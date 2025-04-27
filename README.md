# Fraud Detection in Financial Transactions

## Overview
This project contains a SQL-based solution for detecting fraudulent transactions in a financial system. It includes the creation of a database schema, sample data generation, and a set of queries to identify suspicious activities such as rapid transactions, high-amount transfers, unusual locations, and suspicious devices.

## Features
- **Database Schema:** Defines `Users`, `Transactions`, and `Flagged_Transactions` tables with appropriate relationships.
- **Data Generation:** Populates the database with 500 users and 10,000 transactions, including 500 suspicious ones.
- **Fraud Detection Rules:**
  - Transactions within 5 minutes of each other.
  - Amounts exceeding $5,000.
  - Transactions from unknown locations or rapid location changes.
  - Use of unknown devices.
- **Reporting:** A comprehensive query to view flagged transactions with user details.
- **Optimizations:** Indexes and a stored procedure for efficient fraud detection.

## Getting Started

### Prerequisites
- A MySQL server instance.
- Git installed on your local machine.

### Installation
1. Clone the repository:
   ```
   git clone https://github.com/your-username/fraud-detection-sql.git
   cd fraud-detection-sql
   ```
2. Import the SQL file (`fraud_detection_sql_in_finance.sql`) into your MySQL server:
   - Using MySQL Workbench or command line:
     ```
     mysql -u your_username -p < fraud_detection_sql_in_finance.sql
     ```
   - Enter your MySQL password when prompted.

### Usage
- Run the stored procedure `RunFraudDetection` to flag suspicious transactions:
  ```
  CALL RunFraudDetection();
  ```
- Query the `Flagged_Transactions` table to review results:
  ```
  SELECT * FROM Flagged_Transactions;
  ```

## Folder Structure
- `fraud_detection_sql_in_finance.sql`: Contains the complete SQL script.

## Contributing
Feel free to fork this repository and submit pull requests for improvements or additional fraud detection rules.

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details (if applicable).

## Contact
For questions, please open an issue in the repository or contact the maintainer.

