document.addEventListener('DOMContentLoaded', (event) => {
  let deviceCount = 0; // Keep track of devices to ensure unique IDs

  document.getElementById("addDeviceBtn").addEventListener("click", addDeviceBlock);

  function addDeviceBlock() {
      const deviceName = prompt("Enter device name:");
      const mqttTopic = prompt("Enter MQTT topic for the device:");
      if (!deviceName || !mqttTopic) return; // Cancelled if no input

      deviceCount++;
      const deviceBlock = document.createElement("div");
      deviceBlock.classList.add("deviceBlock");
      deviceBlock.id = "device" + deviceCount;

      deviceBlock.innerHTML = `
          <div class="header" onclick="window.toggleDevice('${deviceBlock.id}')">
              <span class="deviceName">${deviceName}</span>
          </div>
          <div class="content">
              <input type="hidden" class="mqttTopic" value="${mqttTopic}">
              <button class="toggleBtn" onclick="window.toggleSwitch('${deviceBlock.id}', 0)">Off</button>
              <button class="toggleBtn" onclick="window.toggleSwitch('${deviceBlock.id}', 1)">Off</button>
              <button class="toggleBtn" onclick="window.toggleSwitch('${deviceBlock.id}', 2)">Off</button>
              <button class="toggleBtn" onclick="window.toggleSwitch('${deviceBlock.id}', 3)">Off</button>
          </div>
      `;

      document.getElementById("deviceContainer").appendChild(deviceBlock);
  }

  window.toggleDevice = function(deviceId) {
      const deviceBlock = document.getElementById(deviceId);
      const content = deviceBlock.querySelector(".content");
      content.classList.toggle("expanded");
  }

  window.toggleSwitch = function(deviceId, switchIndex) {
      const deviceBlock = document.getElementById(deviceId);
      const toggleBtns = deviceBlock.querySelectorAll('.toggleBtn');
      const toggleBtn = toggleBtns[switchIndex];
      const currentState = toggleBtn.textContent === "On" ? "1" : "0";
      const newState = currentState === "0" ? "1" : "0";
      toggleBtn.textContent = newState === "0" ? "Off" : "On";

      const mqttTopic = deviceBlock.querySelector('.mqttTopic').value;
      const message = switchIndex + ":" + newState;
      sendCommandToDevice(mqttTopic, message);
  };

  function sendCommandToDevice(topic, command) {
    fetch('http://localhost:3000/send-command', { // Ensure this URL matches where your server is running
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ topic, command })
    })
    .then(response => {
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json();
    })
    .then(data => console.log(data))
    .catch(error => console.error('Error:', error));
}

});
