import csv
import argparse
import sqlite3
from dataclasses import dataclass, field
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
DEFAULT_DB_PATH = PROJECT_DIR / "Database" / "base.db"
DEFAULT_POKEMON_CSV_PATH = SCRIPT_DIR / "pkmn.csv"
DEFAULT_TYPES_CSV_PATH = SCRIPT_DIR / "pokemon_types.csv"
DEFAULT_CATCH_CODES_CSV_PATH = SCRIPT_DIR / "catch_codes.csv"


@dataclass(frozen=True)
class PokemonDefinition:
	pokemon_id: int
	name: str
	description: str
	height: float


@dataclass(frozen=True)
class PokemonTypeLink:
	pokemon_id: int
	type_name: str
	type_order: int


@dataclass
class SyncStats:
	pokemon_added: int = 0
	pokemon_updated: int = 0
	pokemon_reactivated: int = 0
	pokemon_deactivated: int = 0
	pokemon_deleted: int = 0
	pokemon_kept_due_to_history: int = 0
	types_added: int = 0
	type_links_added: int = 0
	type_links_updated: int = 0
	type_links_deleted: int = 0
	catch_codes_added: int = 0
	catch_codes_updated: int = 0
	warnings: list[str] = field(default_factory=list)


def parse_args() -> argparse.Namespace:
	parser = argparse.ArgumentParser(
		description="Sync live Pokemon database definitions from the CSV files in Pkmn/."
	)
	parser.add_argument("--db", type=Path, default=DEFAULT_DB_PATH, help="SQLite database path")
	parser.add_argument(
		"--pokemon-csv",
		type=Path,
		default=DEFAULT_POKEMON_CSV_PATH,
		help="Pokemon definition CSV path",
	)
	parser.add_argument(
		"--types-csv",
		type=Path,
		default=DEFAULT_TYPES_CSV_PATH,
		help="Pokemon type definition CSV path",
	)
	parser.add_argument(
		"--catch-codes-csv",
		type=Path,
		default=DEFAULT_CATCH_CODES_CSV_PATH,
		help="Catch code CSV path",
	)
	parser.add_argument(
		"--delete-missing",
		action="store_true",
		help=(
			"Physically delete Pokemon that are missing from pkmn.csv when they have no "
			"FoundPokemon history. Pokemon with history are deactivated instead."
		),
	)
	parser.add_argument(
		"--reactivate-present",
		action="store_true",
		help="Set active = 1 for existing Pokemon that are present in pkmn.csv.",
	)
	parser.add_argument(
		"--dry-run",
		action="store_true",
		help="Run the sync in a transaction and roll it back after printing the summary.",
	)
	return parser.parse_args()


def require_columns(csv_path: Path, fieldnames: list[str] | None, columns: set[str]) -> None:
	if fieldnames is None:
		raise ValueError(f"{csv_path} is empty or missing a header row")

	missing_columns = columns - set(fieldnames)
	if missing_columns:
		missing = ", ".join(sorted(missing_columns))
		raise ValueError(f"{csv_path} is missing required column(s): {missing}")


def parse_int(value: str, csv_path: Path, row_number: int, column_name: str) -> int:
	try:
		return int(value.strip())
	except ValueError as error:
		raise ValueError(
			f"{csv_path}:{row_number} has invalid integer in {column_name}: {value!r}"
		) from error


def parse_float(value: str, csv_path: Path, row_number: int, column_name: str) -> float:
	try:
		return float(value.strip())
	except ValueError as error:
		raise ValueError(
			f"{csv_path}:{row_number} has invalid number in {column_name}: {value!r}"
		) from error


def load_pokemon_definitions(csv_path: Path) -> dict[int, PokemonDefinition]:
	definitions: dict[int, PokemonDefinition] = {}

	with csv_path.open("r", newline="", encoding="utf-8-sig") as csv_file:
		reader = csv.DictReader(csv_file)
		require_columns(csv_path, reader.fieldnames, {"Nr", "Name", "Info", "Height (m)"})

		for row_number, row in enumerate(reader, start=2):
			pokemon_id = parse_int(row["Nr"], csv_path, row_number, "Nr")
			if pokemon_id in definitions:
				raise ValueError(f"{csv_path}:{row_number} duplicates Pokemon ID {pokemon_id}")

			definitions[pokemon_id] = PokemonDefinition(
				pokemon_id=pokemon_id,
				name=row["Name"].strip(),
				description=row["Info"].strip(),
				height=parse_float(row["Height (m)"], csv_path, row_number, "Height (m)"),
			)

	if not definitions:
		raise ValueError(f"{csv_path} did not contain any Pokemon definitions")

	return definitions


def load_type_links(csv_path: Path, valid_pokemon_ids: set[int]) -> list[PokemonTypeLink]:
	links: list[PokemonTypeLink] = []
	seen_type_order: set[tuple[int, int]] = set()
	seen_type_names: set[tuple[int, str]] = set()

	with csv_path.open("r", newline="", encoding="utf-8-sig") as csv_file:
		reader = csv.DictReader(csv_file)
		require_columns(csv_path, reader.fieldnames, {"pokemon_id", "type_name", "type_order"})

		for row_number, row in enumerate(reader, start=2):
			pokemon_id = parse_int(row["pokemon_id"], csv_path, row_number, "pokemon_id")
			type_name = row["type_name"].strip()
			type_order = parse_int(row["type_order"], csv_path, row_number, "type_order")

			if pokemon_id not in valid_pokemon_ids:
				raise ValueError(
					f"{csv_path}:{row_number} references Pokemon ID {pokemon_id}, "
					"but that ID is not in pkmn.csv"
				)
			if not type_name:
				raise ValueError(f"{csv_path}:{row_number} has an empty type_name")
			if type_order < 1:
				raise ValueError(f"{csv_path}:{row_number} has invalid type_order {type_order}")
			if (pokemon_id, type_order) in seen_type_order:
				raise ValueError(
					f"{csv_path}:{row_number} duplicates type_order {type_order} "
					f"for Pokemon ID {pokemon_id}"
				)
			if (pokemon_id, type_name) in seen_type_names:
				raise ValueError(
					f"{csv_path}:{row_number} duplicates type {type_name!r} "
					f"for Pokemon ID {pokemon_id}"
				)

			seen_type_order.add((pokemon_id, type_order))
			seen_type_names.add((pokemon_id, type_name))
			links.append(
				PokemonTypeLink(
					pokemon_id=pokemon_id,
					type_name=type_name,
					type_order=type_order,
				)
			)

	return links


def load_catch_codes(csv_path: Path, valid_pokemon_ids: set[int]) -> dict[int, str]:
	if not csv_path.exists():
		return {}

	catch_codes: dict[int, str] = {}
	seen_codes: dict[str, int] = {}

	with csv_path.open("r", newline="", encoding="utf-8-sig") as csv_file:
		reader = csv.DictReader(csv_file)
		require_columns(csv_path, reader.fieldnames, {"pokemon_id", "catch_code"})

		for row_number, row in enumerate(reader, start=2):
			pokemon_id = parse_int(row["pokemon_id"], csv_path, row_number, "pokemon_id")
			catch_code = row["catch_code"].strip()

			if pokemon_id not in valid_pokemon_ids:
				raise ValueError(
					f"{csv_path}:{row_number} references Pokemon ID {pokemon_id}, "
					"but that ID is not in pkmn.csv"
				)
			if not catch_code:
				raise ValueError(f"{csv_path}:{row_number} has an empty catch_code")
			if pokemon_id in catch_codes:
				raise ValueError(f"{csv_path}:{row_number} duplicates Pokemon ID {pokemon_id}")
			if catch_code in seen_codes:
				raise ValueError(
					f"{csv_path}:{row_number} duplicates catch_code {catch_code!r}; "
					f"already used for Pokemon ID {seen_codes[catch_code]}"
				)

			catch_codes[pokemon_id] = catch_code
			seen_codes[catch_code] = pokemon_id

	return catch_codes


def validate_schema(cursor: sqlite3.Cursor) -> None:
	required_tables = {"Pokemon", "PokemonTypes", "PokemonTypeLinks", "CatchCodes", "FoundPokemon"}
	cursor.execute(
		"SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ({})".format(
			",".join("?" for _ in required_tables)
		),
		tuple(required_tables),
	)
	existing_tables = {row[0] for row in cursor.fetchall()}
	missing_tables = required_tables - existing_tables

	if missing_tables:
		missing = ", ".join(sorted(missing_tables))
		raise RuntimeError(f"Database is missing required table(s): {missing}")


def sync_pokemon(
	cursor: sqlite3.Cursor,
	definitions: dict[int, PokemonDefinition],
	delete_missing: bool,
	reactivate_present: bool,
) -> SyncStats:
	stats = SyncStats()

	cursor.execute("SELECT pokemon_id, name, description, height, active FROM Pokemon")
	existing = {
		int(row[0]): {
			"name": row[1],
			"description": row[2],
			"height": float(row[3]) if row[3] is not None else None,
			"active": bool(row[4]),
		}
		for row in cursor.fetchall()
	}

	for pokemon_id, definition in sorted(definitions.items()):
		current = existing.get(pokemon_id)
		if current is None:
			cursor.execute(
				"""
				INSERT INTO Pokemon (pokemon_id, name, description, height, active)
				VALUES (?, ?, ?, ?, 1)
				""",
				(definition.pokemon_id, definition.name, definition.description, definition.height),
			)
			stats.pokemon_added += 1
			continue

		changed = (
			current["name"] != definition.name
			or current["description"] != definition.description
			or current["height"] != definition.height
		)
		was_inactive = not current["active"]

		if changed or (was_inactive and reactivate_present):
			if reactivate_present:
				cursor.execute(
					"""
					UPDATE Pokemon
					SET name = ?, description = ?, height = ?, active = 1
					WHERE pokemon_id = ?
					""",
					(definition.name, definition.description, definition.height, definition.pokemon_id),
				)
			else:
				cursor.execute(
					"""
					UPDATE Pokemon
					SET name = ?, description = ?, height = ?
					WHERE pokemon_id = ?
					""",
					(definition.name, definition.description, definition.height, definition.pokemon_id),
				)
			if changed:
				stats.pokemon_updated += 1
			if was_inactive and reactivate_present:
				stats.pokemon_reactivated += 1

	csv_pokemon_ids = set(definitions)
	missing_from_csv = sorted(set(existing) - csv_pokemon_ids)
	for pokemon_id in missing_from_csv:
		if delete_missing:
			cursor.execute("SELECT COUNT(*) FROM FoundPokemon WHERE pokemon_id = ?", (pokemon_id,))
			found_count = int(cursor.fetchone()[0])
			if found_count == 0:
				cursor.execute("DELETE FROM PokemonTypeLinks WHERE pokemon_id = ?", (pokemon_id,))
				cursor.execute("DELETE FROM CatchCodes WHERE pokemon_id = ?", (pokemon_id,))
				cursor.execute("DELETE FROM Pokemon WHERE pokemon_id = ?", (pokemon_id,))
				stats.pokemon_deleted += 1
				continue

			stats.pokemon_kept_due_to_history += 1

		if existing[pokemon_id]["active"]:
			cursor.execute("UPDATE Pokemon SET active = 0 WHERE pokemon_id = ?", (pokemon_id,))
			stats.pokemon_deactivated += 1

	return stats


def sync_types(cursor: sqlite3.Cursor, links: list[PokemonTypeLink], pokemon_ids: set[int]) -> SyncStats:
	stats = SyncStats()
	type_names = sorted({link.type_name for link in links})

	cursor.execute("SELECT type_name FROM PokemonTypes")
	existing_type_names = {row[0] for row in cursor.fetchall()}

	for type_name in type_names:
		if type_name not in existing_type_names:
			cursor.execute("INSERT INTO PokemonTypes (type_name) VALUES (?)", (type_name,))
			stats.types_added += 1

	cursor.execute("SELECT type_id, type_name FROM PokemonTypes")
	type_ids_by_name = {row[1]: int(row[0]) for row in cursor.fetchall()}

	cursor.execute(
		"""
		SELECT ptl.pokemon_id, ptl.type_id, ptl.type_order
		FROM PokemonTypeLinks ptl
		WHERE ptl.pokemon_id IN ({})
		""".format(
			",".join("?" for _ in pokemon_ids)
		),
		tuple(sorted(pokemon_ids)),
	)
	existing_links = {
		(int(row[0]), int(row[1])): int(row[2])
		for row in cursor.fetchall()
	}
	desired_links = {
		(link.pokemon_id, type_ids_by_name[link.type_name]): link.type_order
		for link in links
	}

	for key in sorted(set(existing_links) - set(desired_links)):
		cursor.execute(
			"DELETE FROM PokemonTypeLinks WHERE pokemon_id = ? AND type_id = ?",
			key,
		)
		stats.type_links_deleted += 1

	for (pokemon_id, type_id), type_order in sorted(desired_links.items()):
		existing_order = existing_links.get((pokemon_id, type_id))
		if existing_order is None:
			cursor.execute(
				"""
				INSERT INTO PokemonTypeLinks (pokemon_id, type_id, type_order)
				VALUES (?, ?, ?)
				""",
				(pokemon_id, type_id, type_order),
			)
			stats.type_links_added += 1
		elif existing_order != type_order:
			cursor.execute(
				"""
				UPDATE PokemonTypeLinks
				SET type_order = ?
				WHERE pokemon_id = ? AND type_id = ?
				""",
				(type_order, pokemon_id, type_id),
			)
			stats.type_links_updated += 1

	pokemon_ids_with_types = {link.pokemon_id for link in links}
	pokemon_ids_without_types = sorted(pokemon_ids - pokemon_ids_with_types)
	if pokemon_ids_without_types:
		missing_ids = ", ".join(str(pokemon_id) for pokemon_id in pokemon_ids_without_types)
		stats.warnings.append(f"No type definitions found for Pokemon ID(s): {missing_ids}")

	return stats


def sync_catch_codes(
	cursor: sqlite3.Cursor,
	catch_codes: dict[int, str],
	pokemon_ids: set[int],
) -> SyncStats:
	stats = SyncStats()

	if not catch_codes:
		stats.warnings.append("No catch_codes.csv file found; catch codes were not synced")
		return stats

	missing_catch_code_ids = sorted(pokemon_ids - set(catch_codes))
	if missing_catch_code_ids:
		missing_ids = ", ".join(str(pokemon_id) for pokemon_id in missing_catch_code_ids)
		stats.warnings.append(f"No catch codes found for Pokemon ID(s): {missing_ids}")

	for pokemon_id, catch_code in sorted(catch_codes.items()):
		cursor.execute(
			"SELECT pokemon_id FROM CatchCodes WHERE catch_code = ? AND pokemon_id != ?",
			(catch_code, pokemon_id),
		)
		conflicting_row = cursor.fetchone()
		if conflicting_row is not None:
			raise ValueError(
				f"Catch code {catch_code!r} is already assigned to Pokemon ID {conflicting_row[0]}"
			)

		cursor.execute("SELECT catch_code FROM CatchCodes WHERE pokemon_id = ?", (pokemon_id,))
		existing_codes = {row[0] for row in cursor.fetchall()}

		if existing_codes == {catch_code}:
			continue

		cursor.execute("DELETE FROM CatchCodes WHERE pokemon_id = ?", (pokemon_id,))
		cursor.execute(
			"INSERT INTO CatchCodes (pokemon_id, catch_code) VALUES (?, ?)",
			(pokemon_id, catch_code),
		)

		if existing_codes:
			stats.catch_codes_updated += 1
		else:
			stats.catch_codes_added += 1

	return stats


def combine_stats(stats: SyncStats, other: SyncStats) -> SyncStats:
	stats.pokemon_added += other.pokemon_added
	stats.pokemon_updated += other.pokemon_updated
	stats.pokemon_reactivated += other.pokemon_reactivated
	stats.pokemon_deactivated += other.pokemon_deactivated
	stats.pokemon_deleted += other.pokemon_deleted
	stats.pokemon_kept_due_to_history += other.pokemon_kept_due_to_history
	stats.types_added += other.types_added
	stats.type_links_added += other.type_links_added
	stats.type_links_updated += other.type_links_updated
	stats.type_links_deleted += other.type_links_deleted
	stats.catch_codes_added += other.catch_codes_added
	stats.catch_codes_updated += other.catch_codes_updated
	stats.warnings.extend(other.warnings)
	return stats


def run_sync(args: argparse.Namespace) -> SyncStats:
	db_path = args.db.resolve()
	pokemon_csv_path = args.pokemon_csv.resolve()
	types_csv_path = args.types_csv.resolve()
	catch_codes_csv_path = args.catch_codes_csv.resolve()

	if not db_path.exists():
		raise FileNotFoundError(f"Database does not exist: {db_path}")
	if not pokemon_csv_path.exists():
		raise FileNotFoundError(f"Pokemon CSV does not exist: {pokemon_csv_path}")
	if not types_csv_path.exists():
		raise FileNotFoundError(f"Pokemon types CSV does not exist: {types_csv_path}")

	definitions = load_pokemon_definitions(pokemon_csv_path)
	pokemon_ids = set(definitions)
	type_links = load_type_links(types_csv_path, pokemon_ids)
	catch_codes = load_catch_codes(catch_codes_csv_path, pokemon_ids)

	conn = sqlite3.connect(db_path)
	try:
		conn.execute("PRAGMA foreign_keys = ON")
		cursor = conn.cursor()
		validate_schema(cursor)

		stats = sync_pokemon(cursor, definitions, args.delete_missing, args.reactivate_present)
		combine_stats(stats, sync_types(cursor, type_links, pokemon_ids))
		combine_stats(stats, sync_catch_codes(cursor, catch_codes, pokemon_ids))

		if args.dry_run:
			conn.rollback()
		else:
			conn.commit()

		return stats
	except Exception:
		conn.rollback()
		raise
	finally:
		conn.close()


def print_summary(stats: SyncStats, dry_run: bool) -> None:
	title = "Dry-run complete; no database changes were written." if dry_run else "Pokemon database sync complete."
	print(title)
	print(f"Pokemon added: {stats.pokemon_added}")
	print(f"Pokemon updated: {stats.pokemon_updated}")
	print(f"Pokemon reactivated: {stats.pokemon_reactivated}")
	print(f"Pokemon deactivated: {stats.pokemon_deactivated}")
	print(f"Pokemon deleted: {stats.pokemon_deleted}")
	print(f"Pokemon kept due to FoundPokemon history: {stats.pokemon_kept_due_to_history}")
	print(f"Types added: {stats.types_added}")
	print(f"Type links added: {stats.type_links_added}")
	print(f"Type links updated: {stats.type_links_updated}")
	print(f"Type links deleted: {stats.type_links_deleted}")
	print(f"Catch codes added: {stats.catch_codes_added}")
	print(f"Catch codes updated: {stats.catch_codes_updated}")

	for warning in stats.warnings:
		print(f"Warning: {warning}")


def main() -> None:
	args = parse_args()
	stats = run_sync(args)
	print_summary(stats, args.dry_run)


if __name__ == "__main__":
	main()