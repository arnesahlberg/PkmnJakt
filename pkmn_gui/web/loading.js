// Hide loading screen when Flutter app is initialized
window.addEventListener('load', function() {
  var loading = document.getElementById('loading');
  var loadingText = document.getElementById('loading-text');
  
  // Loading messages to cycle through
  var loadingMessages = [
    "Laddar Pokémon...",
    "Synkar med lägerledningen...",
    "Kompenserar för väder...",
    "Läser Pokémon-stadgarna...",
    "Letar efter Pokébollar i bollförrådet...",
    "Försöker starta upp QR läsaren...",
    "Startar Pokédex...",
    "Det kan ta en liten stund...",
    "Ber Mats om hjälp...",
    "Letar efter sällsynta Pokémon...",
    "Kollar med kansliet...",
    "Kollar så toplistan stämmer...",
    "Kollar om vi följer alla regelverk...",
    "Skickar kallelse till alla Pokémon...",
    "Gömmer Pokémon på luriga ställen...",
    "Gömmer legendariska Pokemon på extra luriga ställen...",
    "Räknar poäng...",
    "Förbereder PokéDex...",
    "Letar efter databas...",
    "Laddar Pokédex...",
    "Laddar milstolpar...",
    "Gått vilse i skogen, vänta lite...",
    "Hämtar borttappade Pokébollar...",
    "Jagar rymda Pokémon...",
    "Putsar Pokébollar...",
    "Syncar med övriga programpunkter...",
    "Stretchar lite...",
    "Ser till att Pokémon som är släkt finns nära varandra...",
    "Ser till att kraftigare Pokémon är mer gömda ...",
    "Felsöker datacentret...",
    "Aktiverar Pokéscan...",
    "Ladda highscorelistan...",
    "Fixar fel QR kod på Porygon...",
    "Flyttar fixad Porygon lite...",
    "Byter ut trasiga kritor...",
    "Letar buggar..."
  ];
  
  // Function to cycle through loading messages randomly
  var messageIndex = 0;
  var previousIndex = -1;
  function cycleLoadingMessages() {
    // avoid same message twice
    do {
      messageIndex = Math.floor(Math.random() * loadingMessages.length);
    } while (messageIndex === previousIndex && loadingMessages.length > 1);
    
    loadingText.textContent = loadingMessages[messageIndex];
    previousIndex = messageIndex;
  }
  
  // Start cycling messages
  cycleLoadingMessages();
  var messageInterval = setInterval(cycleLoadingMessages, 1800);
  
  // Function to hide loading screen
  function hideLoading() {
    clearInterval(messageInterval);
    loading.style.opacity = '0';
    setTimeout(function() {
      loading.style.display = 'none';
    }, 500);
  }
  
  // Hide loading screen when Flutter is initialized
  window.addEventListener('flutter-first-frame', function() {
    setTimeout(hideLoading, 500);
  });
  
  // // Fallback - hide loading after 10 seconds (remove)
  // setTimeout(function() {
  //   if (loading.style.opacity !== '0') {
  //     hideLoading();
  //   }
  // }, 10000);
});
