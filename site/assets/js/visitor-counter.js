// visitor-counter.js
// NOTE: Replace with actual API Gateway endpoint URL for deployment
const apiEndpoint = "https://your-api-gateway-url.amazonaws.com/prod/visitor-count";

window.addEventListener("DOMContentLoaded", async () => {
  try {
    const res = await fetch(apiEndpoint);
    const data = await res.json();

    const counter = document.getElementById("visitor-count");
    if (counter) {
      counter.textContent = data.count;
    }
  } catch (err) {
    console.error("Error fetching visitor count:", err);
  }
});
