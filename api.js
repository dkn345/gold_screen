// API Helper Functions
const API_BASE_URL = 'http://localhost:3000/api';

// Fetch all movies
async function fetchMovies() {
  try {
    const response = await fetch(`${API_BASE_URL}/movies`);
    if (!response.ok) throw new Error('Failed to fetch movies');
    return await response.json();
  } catch (error) {
    console.error('Error fetching movies:', error);
    return [];
  }
}

// Fetch all shows
async function fetchShows() {
  try {
    const response = await fetch(`${API_BASE_URL}/shows`);
    if (!response.ok) throw new Error('Failed to fetch shows');
    return await response.json();
  } catch (error) {
    console.error('Error fetching shows:', error);
    return [];
  }
}

// Fetch distinct show dates
async function fetchShowDates() {
  try {
    const response = await fetch(`${API_BASE_URL}/show-dates`);
    if (!response.ok) throw new Error('Failed to fetch show dates');
    return await response.json();
  } catch (error) {
    console.error('Error fetching show dates:', error);
    return [];
  }
}

// Fetch showtimes for a movie on a specific date
async function fetchShowtimes(movieId, date) {
  try {
    const url = date
      ? `${API_BASE_URL}/showtimes/${movieId}?date=${encodeURIComponent(date)}`
      : `${API_BASE_URL}/showtimes/${movieId}`;
    const response = await fetch(url);
    if (!response.ok) throw new Error('Failed to fetch showtimes');
    return await response.json();
  } catch (error) {
    console.error('Error fetching showtimes:', error);
    return [];
  }
}

// Fetch all concessions
async function fetchConcessions() {
  try {
    const response = await fetch(`${API_BASE_URL}/concessions`);
    if (!response.ok) throw new Error('Failed to fetch concessions');
    return await response.json();
  } catch (error) {
    console.error('Error fetching concessions:', error);
    return [];
  }
}

// Fetch customer by ID
async function fetchCustomer(customerId) {
  try {
    const response = await fetch(`${API_BASE_URL}/customers/${customerId}`);
    if (!response.ok) throw new Error('Failed to fetch customer');
    return await response.json();
  } catch (error) {
    console.error('Error fetching customer:', error);
    return null;
  }
}

// Add item to cart
async function addToCart(customerId, itemId, quantity) {
  try {
    const response = await fetch(`${API_BASE_URL}/cart`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ customer_id: customerId, item_id: itemId, quantity })
    });
    if (!response.ok) throw new Error('Failed to add to cart');
    return await response.json();
  } catch (error) {
    console.error('Error adding to cart:', error);
    return null;
  }
}

// Get cart from localStorage
function getCartFromStorage() {
  const cart = localStorage.getItem('cart');
  return cart ? JSON.parse(cart) : [];
}

// Save cart to localStorage
function saveCartToStorage(cart) {
  localStorage.setItem('cart', JSON.stringify(cart));
}

// Add item to local cart
function addItemToLocalCart(item) {
  const cart = getCartFromStorage();
  const existingItem = cart.find(i => i.id === item.id);
  
  if (existingItem) {
    existingItem.quantity += 1;
  } else {
    cart.push({ ...item, quantity: 1 });
  }
  
  saveCartToStorage(cart);
  return cart;
}
