1.	Autentisering och användarhantering
    -	POST /login
    -	Request: Inkludera en id‑sträng (t.ex. bandets id)
    -	Response: Bekräftelse (t.ex. ett JWT-token, användarinfo) om inloggning lyckas, eller felmeddelande om användaren inte hittas.
    -	POST /logout
    -	Request: Token eller användar-id (beroende på hur sessionshanteringen implementeras)
    -	Response: Bekräftelse på att utloggningen lyckades.
    -	(Eventuellt) POST /register
    -	Request: Ny användare med id‑sträng, namn, telefon och e-post
    -	Response: Bekräftelse på att kontot skapats eller felmeddelande vid problem.
2.	Registrera funna Pokémon (utan foto)
    -	POST /found-pokemon
    -	Request: Användar‑id samt en textsträng eller identifierare för Pokémon (t.ex. Pokémon‑nummer eller namn)
    -	Response: Bekräftelse på att posten skapats, med eventuell flagga om användaren redan registrerat den, eller ett felmeddelande vid problem.
3.	Uppladdning och hantering av fotografier
    -	POST /upload-photo
    -	Request: Användar‑id, Pokémon‑id (eller motsvarande textsträng), bilddata (t.ex. base64‑kodad) och eventuellt en frivillig kommentar
    -	Response: Bekräftelse att fotot mottagits, samt information om rating (t.ex. en förvald rating eller en notis om att det är väntande bedömning).
    -	PATCH /update-photo/{photo_id}
    -	Request: Användar‑id, Pokémon‑id, ny bilddata (base64) och/eller uppdaterad kommentar och rating
    -	Response: Bekräftelse på att ändringen sparats, eller ett felmeddelande om något gick fel.
    -	DELETE /photo/{photo_id}
    -	Request: Användar‑id och photo_id
    -	Response: Bekräftelse på att bilden raderats eller ett felmeddelande om borttagning misslyckades.
4.	Fråga ut statistik och topplistor
    -	GET /top10/found
    -	Response: Lista med de 10 användare som hittat flest Pokémon (baserat på antal poster i FoundPokemon).
    -	GET /top10/photos
    -	Response: Lista med de 10 användare som laddat upp flest fotografier (alternativt de med högst sammanlagd rating).
    -	GET /recent-photos
    -	Request: Eventuellt med parameter för antal poster, eller “efter” en viss tidpunkt
    -	Response: Senaste uppladdade bilder, med associerad användare, Pokémon och övrig info.
    -	GET /photos/pokemon/{pokemon_id}
    -	Response: Bilder som laddats upp för en specifik Pokémon (kan eventuellt kombineras med filter, t.ex. topp 10 baserat på rating).
    -	GET /top-rated-photos
    -	Response: Lista med exempelvis de 10 bilder med högst rating, med användarinfo, Pokémon-info och rating.
5.	Övriga endpoints (tillval)
    -	GET /user/{user_id}/found
    -	Response: Lista på alla Pokémon som en specifik användare har registrerat.
    -	GET /user/{user_id}/photos
    -	Response: Alla fotografier uppladdade av en specifik användare.