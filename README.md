# AppTech – Reward-Based Typing App (Built with Flutter & Firebase)

AppTech is a reward-based mobile application where users can earn virtual cash by typing. Designed to promote consistent engagement, habit-building, and instant gratification, the app enables users to accumulate points through daily missions and redeem them for gift cards. It includes gamified UI, real-time progress tracking, and a plan for cloud-native architecture using AWS.

---

## ✨ Key Features

* **🎯 Typing-to-Earn System**: Earn 1 point per 10 characters typed (up to 100 points per day)
* **📊 Visual Progress Tracker**: Circular progress bar shows daily goal completion
* **🛙 Gifticon Store**: Use points to redeem Starbucks, McDonald's coupons, and more
* **👤 Profile Dashboard**: View typing history, daily stats, and current balance
* **🔐 Secure Auth**: Firebase Authentication for safe login and sign-up
* **🧪 Experimental Tab (Coming Soon)**: A free-form typing/memo pad feature to build consistent typing habits beyond the gamified system

---

## 🚀 Tech Stack Overview

| Layer         | Technology                        |
| ------------- | --------------------------------- |
| Frontend      | Flutter (Dart)                    |
| State Mgmt    | Provider Pattern                  |
| Backend       | Firebase (Auth + Firestore)       |
| Ads           | Google AdMob                      |
| Platforms     | iOS, Android, Web (in progress)   |
| Planned Cloud | AWS Lambda, API Gateway, DynamoDB |

---

## ☁️ Cloud-Native Migration Plan (Planned)

While the current MVP leverages Firebase for simplicity and rapid iteration, I plan to migrate to a serverless architecture using:

* **AWS Lambda** for backend logic
* **API Gateway** for managing HTTP endpoints
* **DynamoDB** as a scalable NoSQL alternative to MySQL

This transition will allow the system to scale with user growth, improve performance, and reduce backend maintenance overhead.

---

## 🔧 Project Architecture

```
apptech/
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── services/
│   │   └── widgets/
│   ├── android/
│   ├── ios/
│   └── web/
└── backend/ (planned)
```

---

## 📸 Screens Overview *(Screenshots Coming Soon)*

* **Home Screen**: Real-time progress bar, daily goal indicator, bonus reward display
* **Typing Screen**: Live character counter, animated feedback, debounce optimization
* **Store Screen**: Grid layout gifticon items, point balance, and purchase flow
* **Profile Screen**: Total stats, session logs, settings, and logout option

---

## 🚧 Getting Started

### Prerequisites

* Flutter SDK >= 3.0.0
* Dart SDK >= 2.17.0
* Firebase project setup (Auth + Firestore)

### Installation

```bash
# Clone the repository
git clone https://github.com/zpdl768/apptech-frontend.git
cd apptech-frontend

# Install dependencies
flutter pub get

# Configure Firebase
# (firebase_options.dart required)

# Run the app
flutter run
```

---

## 🚫 Typing & Reward Rules

* **Typing Rule**: Every 10 characters = 1 point
* **Daily Cap**: Maximum 100 points per day
* **Real-time Feedback**: Points instantly reflected
* **Usage**: Tap to collect, spend in store, or accumulate

---

## 🚚 Development Status & Plans

* Firebase-backed MVP is live
* Serverless migration (Lambda + DynamoDB) in roadmap
* Secondary typing tab (memo/logging) feature under design
* Web version coming soon (responsive layout WIP)

---

## 📢 Feedback & Contribution

This project is under active development. Feedback, feature ideas, and PRs are welcome!

---

## 👨‍💻 About the Developer

Created by [YeoMyeong Kim](https://github.com/zpdl768) — a full-stack developer focused on practical, scalable app development. Passionate about combining beautiful UI with clean architecture and transitioning into cloud-native environments.

> This project was designed, developed, and deployed end-to-end as a showcase of my engineering skills.

