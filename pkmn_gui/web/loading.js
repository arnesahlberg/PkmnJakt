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
    "Åh-nej, måste börja om igen...",
  ];
  
  // Function to cycle through loading messages
  var messageIndex = 0;
  function cycleLoadingMessages() {
    loadingText.textContent = loadingMessages[messageIndex];
    messageIndex = (messageIndex + 1) % loadingMessages.length;
  }
  
  // Start cycling messages
  cycleLoadingMessages();
  var messageInterval = setInterval(cycleLoadingMessages, 2000);
  
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
  
  // Fallback - hide loading after 10 seconds
  setTimeout(function() {
    if (loading.style.opacity !== '0') {
      hideLoading();
    }
  }, 10000);
});
