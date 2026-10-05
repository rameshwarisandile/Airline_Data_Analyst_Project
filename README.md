# ✈️ Airline Data Analyst Project

## 📌 Project Overview

This project is a SQL-based Airline Data Analytics project developed to analyze airline operations, flight delays, cancellations, airport performance, and passenger satisfaction.

The project uses real-world airline datasets and SQL to answer practical business questions and generate meaningful insights for airline management.

The analysis focuses on two major areas:

- Airline Operational Performance
- Passenger Satisfaction & Experience

The goal is to convert raw airline data into useful business insights that can support better operational and customer-experience decisions.

---

## 🎯 Business Problem

Airlines generate large amounts of operational and passenger data every day. However, raw data alone does not provide clear answers to important business questions.

This project analyzes the data to answer questions such as:

- How many flights operated and what percentage were cancelled or diverted?
- Which airlines have better or worse reliability?
- Which airlines have the highest cancellation rates?
- What are the major reasons for flight cancellations?
- Which months have higher delays and cancellations?
- Which days of the week have more delayed flights?
- At what time of day are flights more likely to be delayed?
- What are the main causes of flight delays?
- Which airports have the highest delay rates?
- Which airlines perform better or worse than the industry average?
- What percentage of passengers are satisfied?
- Which passenger segments have higher or lower satisfaction?
- Which age groups are more satisfied?
- Does flight delay affect passenger satisfaction?
- Which service factors are the strongest drivers of passenger satisfaction?
- Which travel classes perform better for different travel purposes?
- Which passenger segments should be prioritized for improvement?

---

# 📂 Dataset

The project uses multiple airline datasets.

## 1. Passenger Satisfaction Dataset

**File:** `airline_passenger_satisfaction.csv`

This dataset contains passenger-level information such as:

- Gender
- Age
- Customer Type
- Type of Travel
- Travel Class
- Flight Distance
- Departure Delay
- Arrival Delay
- Online Booking
- Check-in Service
- Online Boarding
- Gate Location
- On-board Service
- Seat Comfort
- Leg Room
- Cleanliness
- Food & Drink
- In-flight Service
- Wi-Fi
- Entertainment
- Baggage Handling
- Overall Satisfaction

The dataset contains approximately **129,880 passenger records**.

---

## 2. Airlines Dataset

**File:** `airlines.csv`

Contains airline information including:

- IATA Code
- Airline Name

---

## 3. Airports Dataset

**File:** `airports.csv`

Contains airport information including:

- IATA Code
- Airport Name
- City
- State
- Country
- Latitude
- Longitude

The dataset contains **322 airports**.

---

## 4. Cancellation Codes Dataset

**File:** `cancellation_codes.csv`

Contains cancellation reason codes and their descriptions.

---

## 5. Flights Dataset

**File:** `flights.csv`

Contains flight operational information including:

- Month
- Day
- Day of Week
- Airline
- Origin Airport
- Destination Airport
- Scheduled Departure
- Departure Delay
- Arrival Delay
- Flight Distance
- Diverted Status
- Cancelled Status
- Cancellation Reason
- Air System Delay
- Security Delay
- Airline Delay
- Late Aircraft Delay
- Weather Delay

---

## 6. Data Dictionary

**File:** `data_dictionary.csv`

Contains descriptions of the fields used in the airline datasets.

---

# 🗄️ Database Structure

The project creates a MySQL database named:

```text
airline_project
