# SmartStyle - AI-Powered Smart Wardrobe

**SmartStyle** is an AI-based smart wardrobe assistant that helps users choose the perfect outfit based on their **mood (detected via phone camera), current weather**, and **occasion**. It’s designed to save time, personalize fashion, and bring smart automation to daily clothing decisions.

## Demo Video
https://drive.google.com/file/d/1IzDVSTNqclCBaswjFOO_CmgWfjc8M23n/view?usp=drive_link

## Features

- **Mood-Based Outfit Selection**  
  Detects your current mood using facial analysis via Phone camera and selects matching outfits.

- **Weather Integration**  
  Syncs with real-time weather APIs to suggest clothes suitable for the current conditions.

- **Occasion-Based Filtering**  
  Choose the event type(casual or formal), and SmartStyle filters the outfits accordingly.

- **Smart Wardrobe Scanning**  
  Upload images of your clothes via the mobile app — they are auto-classified and added to the virtual wardrobe.

- **Machine Learning-Powered**  
  Uses ML for mood detection, color classification, and weather-occasion-outfit prediction.

---

## Technologies Used

- **Flutter** – For the mobile app interface
- **Python** – Backend ML scripts and API integration
- **TensorFlow Lite** – On-device mood/emotion and clothes recognition model
- **Firebase** – Authentication, image storage, and wardrobe DB 
- **OpenWeatherMap API** – For real-time weather data

---

##  Setup Instructions

1. **Clone the Repository**

   ```bash
   git clone https://github.com/monish114/SmartStyle-Project.git
   cd SmartStyle
