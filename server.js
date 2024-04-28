const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const mqtt = require('mqtt');
const path = require('path'); // Require path module

const app = express();
const port = 3000;
const mqttClient = mqtt.connect('mqtt://192.168.0.5:1883'); // Or use your broker's IP address

app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public')); // Serve static files from the 'public' directory

mqttClient.on('connect', () => {
    console.log('Connected to MQTT broker');
});

app.post('/send-command', (req, res) => {
    const { topic, command } = req.body;
    mqttClient.publish(topic, command, {}, (error) => {
        if (error) {
            console.error('Publish error:', error);
            res.status(500).json({ error: 'Failed to publish command' });
        } else {
            res.json({ success: true, message: `Command "${command}" sent to topic "${topic}"` });
        }
    });
});

// Serve the HTML file on the root route
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html')); // Ensure 'index.html' is in the 'public' folder
});

app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});
