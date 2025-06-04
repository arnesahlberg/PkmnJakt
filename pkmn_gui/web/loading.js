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
    "Äter lite kruska...",
    "Förbereder jakten...",
    "Kollar med kansliet...",
    "Kollar internet...",
    "Kollar om vi följer alla regelverk...",
    "Skickar kallelse till alla Pokémon...",
    "Räknar Pokémon...",
    "Räknar Pokébollar...",
    "Räknar poäng...",
    "Förbereder PokéDex...",
    "Letar efter databas...",
    "Laddar Pokédex...",
    "Laddar poängsystem...",
    "Gått vilse i skogen, vänta lite...",
    "Hämtar borttappade Pokébollar...",
    "Jagar rymda Pokémon...",
    "Putsar Pokébollar...",
    "Syncar med övriga programpunkter...",
    "Stretchar lite...",
    "Morgongyma...",
    "Kollar med Mats...",
    "Felsöker datacentret...",
    "Aktiverar Pokéscan...",
    "Ladda highscorelistan..."
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
