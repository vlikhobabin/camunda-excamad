// Production configuration for EXCAMAD application
export const PRODUCTION_CONFIG = {
  // Определяем продакшн среду по домену
  isProduction: () => {
    return window.location.hostname === 'excamad.eg-holding.ru';
  },
  
  // Базовый URL для продакшена
  getBaseUrl: () => {
    if (window.location.hostname === 'excamad.eg-holding.ru') {
      return 'https://excamad.eg-holding.ru';
    }
    return window.location.origin;
  }
}; 