export function generatePossibleUrl() {
  // Define the list of possible Camunda URLs.
  // We start with your primary server.
  const arrayOfPossibleUlr = ['https://camunda.eg-holding.ru/engine-rest/'];

  // This part of the code adds any extra URLs you might have saved in the browser's local storage.
  if (localStorage.listOfUrl) {
    const list = JSON.parse(localStorage.listOfUrl);
    list.forEach(item => {
      // Add the item only if it's not already in our list to prevent duplicates.
      if (arrayOfPossibleUlr.indexOf(item) === -1) {
        arrayOfPossibleUlr.push(item);
      }
    });
  }

  return arrayOfPossibleUlr;
}
