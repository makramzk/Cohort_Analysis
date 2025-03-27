## Customer Retention & Cohort Analysis with Databricks 🚀
### Overview
This project builds a modern marketing analytics solution to study customer retention and repeat purchase behavior. By leveraging Fivetran, Databricks, and Delta Lake, we ingest, transform, and analyze e-commerce sales data to visualize cohort trends.

### Key Objectives:
✅ Ingest e-commerce sales data from a GCP Cloud SQL (BigQuery) database using Fivetran.
✅ Transform & Model the data in Databricks using Delta Lake.
✅ Analyze & Visualize customer retention and cohort trends in a Databricks Dashboard.

By the end of this project, you'll have a clear understanding of how the modern data stack enables seamless data ingestion, transformation, and visualization to uncover insights into customer behavior.

### Use Case Background
Why is this important?
Customer acquisition is expensive, making it critical for businesses to analyze retention trends. This project focuses on cohort analysis, a technique that groups customers based on a shared characteristic (e.g., first purchase date) to answer:

How long does it take for customers to make their second purchase, and how does this vary across different cohorts?

### Project Workflow
1️⃣ Data Ingestion using Fivetran
🔹 Connect to a GCP Cloud SQL (BigQuery) database that stores e-commerce sales data.
🔹 Automate table and schema replication into Delta Lake in Databricks.

2️⃣ Data Transformation using Databricks
🔹 Transform raw sales data into a cohort analysis-optimized model.
🔹 Use SQL (CTEs & subqueries) to compute each customer’s first and second purchase dates.

3️⃣ Cohort Analysis & Visualization
🔹 Build visual dashboards in Databricks to explore trends.
🔹 Analyze time to second purchase and retention patterns across cohorts.

### Technology Stack
🔹 Cloud Database: Google Cloud SQL (BigQuery)
🔹 ETL Pipeline: Fivetran
🔹 Data Processing & Modeling: Databricks (SQL, Delta Lake)
🔹 Visualization: Databricks Dashboard

### Results & Insights
📊 This project provides data-driven insights into customer retention trends:
✅ How quickly customers make a repeat purchase.
✅ Differences in retention across cohorts.
✅ Potential areas for improving customer loyalty.

