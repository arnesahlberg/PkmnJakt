# for release we want to use ssl certificates in nginx, so we don't need to set them up here
DATABASE_PATH=../Database/base.db PORT=5401 cargo run --release