
# Employee Attrition Prediction & Analysis

### Portfolio Project: Machine Learning & HR Analytics

---

## Project Overview

In this repository, we build, evaluate, and compare two different machine learning models (**Logistic Regression** and **Random Forest Classifier**) to predict employee turnover. Our goal is to identify the primary drivers of attrition and evaluate whether linear models or non-linear ensemble methods handle human resources data more effectively.

---

## Dataset Structure

The analysis incorporates two primary data perspectives:

1. **Aggregated Organizational Dataset (`df_agg`)**: Sourced via SQL exports (`../sql/attrition_aggregate.csv`), this dataset tracks macro-level organizational metrics across 85 distinct department and management tier combinations.
   * **Key Columns**: `department_name`, `management_tier`, `total_headcount`, `total_attrition_count`, `attrition_rate_pct`, `avg_base_salary`, `avg_tenure_years`, and `avg_performance_rating`.

2. **Individual Employee Records**: Used for training predictive classification models to isolate personal turnover indicators.

---

## Key Features & Workflow

* **Data Manipulation & Preprocessing**: Handled via `pandas` and `numpy`, utilizing `SimpleImputer` and `StandardScaler` within scikit-learn pipelines.
* **Exploratory Visualizations**: Visualized trailing attrition rates, salary distributions, and performance ratings across organizational tiers using `matplotlib` and `seaborn`.
* **Predictive Modeling**: Trained and evaluated both parametric (**Logistic Regression**) and non-linear ensemble (**Random Forest Classifier**) models.
* **Performance Metrics**: Assessed models using ROC-AUC scores, ROC curves, and detailed classification reports.

---

## Getting Started

### Prerequisites

Ensure you have the following Python libraries installed in your environment:

```
pip install pandas numpy matplotlib seaborn scikit-learn
```


### Running the Notebook

1. Clone or download the repository.
2. Ensure the SQL export datasets are located at `../csv/attrition_aggregate.csv`.
3. Launch Jupyter Notebook and run the analysis pipeline sequentially.
