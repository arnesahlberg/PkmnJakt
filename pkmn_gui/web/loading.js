// Hide loading screen when Flutter app is initialized
window.addEventListener('load', function() {
  var loading = document.getElementById('loading');
  var loadingText = document.getElementById('loading-text');
  var loadingOpacity = 1;
  
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
  
  // Function to hide loading screen with fade effect
  function hideLoading() {
    // Clear the message cycling interval
    clearInterval(messageInterval);
    
    // Simply fade out the loading screen
    if (loadingOpacity > 0) {
      loadingOpacity -= 0.05;
      loading.style.opacity = loadingOpacity;
      if (loadingOpacity <= 0) {
        loading.style.display = 'none';
      } else {
        requestAnimationFrame(hideLoading);
      }
    }
  }
  
  // Start hiding the loading screen when Flutter is initialized
  window.addEventListener('flutter-first-frame', function() {
    setTimeout(hideLoading, 500);
  });
  
  // Fallback - hide loading after 10 seconds even if Flutter doesn't initialize
  setTimeout(function() {
    if (loading.style.opacity !== '0') {
      hideLoading();
    }
  }, 10000);
});
