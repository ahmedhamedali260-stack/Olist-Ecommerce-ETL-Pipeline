import os
import urllib.parse
import numpy as np
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine

# ============================================================
# 1. الاتصال بـ MySQL عبر المتغيرات البيئية (.env)
# ============================================================
load_dotenv()

DB_USER = os.getenv("DB_USER", "root")
DB_PASS = os.getenv("DB_PASS", "Orcl@2026#Db!")
DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_NAME = os.getenv("DB_NAME", "ECOMMERCE")

# تشفير/ترميز الباسورد لو فيه رموز خاصة مثل @ و #
safe_password = urllib.parse.quote_plus(DB_PASS)

engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{safe_password}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

print("✅ تم الاتصال بقاعدة البيانات")

# ============================================================
# 2. EXTRACT
# ============================================================
df_orders = pd.read_sql("SELECT * FROM OLIST_ORDER", con=engine)
df_items = pd.read_sql("SELECT * FROM ORDER_ITEMS", con=engine)
df_products = pd.read_sql("SELECT * FROM PRODUCTS", con=engine)
df_sellers = pd.read_sql("SELECT * FROM SELLERS", con=engine)
df_customers = pd.read_sql("SELECT * FROM CUSTOMER", con=engine)
df_payments = pd.read_sql("SELECT * FROM PAYMENT", con=engine)

# تنظيف أسماء الأعمدة
for df in [df_orders, df_items, df_products, df_sellers, df_customers, df_payments]:
    df.columns = df.columns.str.strip().str.lower()

print("✅ تم استخراج البيانات من MySQL")

# ============================================================
# 3. TRANSFORM
# ============================================================

# A) دمج Order Items + Products + Sellers
df_items_detailed = (
    df_items
    .merge(df_products, on="product_id", how="inner")
    .merge(df_sellers, on="seller_id", how="inner")
)

# B) تجميع الدفعات على مستوى الطلب
pay_agg = (
    df_payments
    .groupby("order_id", as_index=False)
    .agg(payment_value=("payment_value", "sum"))
)

# C) دمج الطلبات + العملاء + الدفعات
df_full_orders = (
    df_orders
    .merge(df_customers, on="customer_id", how="left")
    .merge(pay_agg, on="order_id", how="left")
)

# D) تنظيف النصوص
df_full_orders["customer_city"] = (
    df_full_orders["customer_city"]
    .astype("string")
    .str.strip()
    .str.lower()
    .fillna("unknown")
)

df_items_detailed["product_category_name"] = (
    df_items_detailed["product_category_name"]
    .astype("string")
    .str.strip()
    .str.lower()
    .fillna("unknown")
)

# E) تحويل التواريخ
for col in ["order_purchase_timestamp", "order_delivered_customer_date"]:
    df_full_orders[col] = pd.to_datetime(df_full_orders[col], errors="coerce")

# F) حساب مدة التوصيل بالأيام
df_full_orders["delivery_days"] = (
    df_full_orders["order_delivered_customer_date"]
    - df_full_orders["order_purchase_timestamp"]
).dt.total_seconds() / (60 * 60 * 24)

# G) تنظيف السعر
df_items_detailed["price_clean"] = np.where(
    df_items_detailed["price"].isna() | (df_items_detailed["price"] <= 0),
    np.nan,
    df_items_detailed["price"]
)

# H) تنظيف قيمة الشحن
df_items_detailed["freight_value_clipped"] = np.clip(
    df_items_detailed["freight_value"],
    a_min=0,
    a_max=200
)

# I) تصنيف سرعة التوصيل
delivered = df_full_orders["order_status"].astype("string").str.lower().eq("delivered")
d = df_full_orders["delivery_days"]

df_full_orders["delivery_speed"] = np.select(
    [
        delivered & (d <= 5),
        delivered & (d > 5) & (d <= 12),
        delivered & (d > 12)
    ],
    ["Fast", "Normal", "Delayed"],
    default="Unknown"
)

# ============================================================
# 4. ANALYTICS
# ============================================================
category_performance = (
    df_items_detailed
    .groupby("product_category_name")
    .agg(
        total_revenue=("price_clean", "sum"),
        avg_price=("price_clean", "mean"),
        total_freight=("freight_value_clipped", "sum"),
        total_items_sold=("order_item_id", "count"),
        valid_price_items=("price_clean", "count")
    )
    .reset_index()
)

delivered_orders = df_full_orders[delivered].copy()
avg_delivery = (
    delivered_orders
    .groupby("customer_city")["delivery_days"]
    .mean()
    .rename("avg_delivery_days")
)

city_performance = (
    df_full_orders
    .groupby("customer_city")
    .agg(
        total_orders=("order_id", "nunique"),
        total_sales=("payment_value", "sum")
    )
    .join(avg_delivery)
    .reset_index()
)

# ============================================================
# 5. LOAD
# ============================================================
category_performance.to_sql(
    "category_performance_analytics",
    con=engine,
    if_exists="replace",
    index=False
)

city_performance.to_sql(
    "city_performance_analytics",
    con=engine,
    if_exists="replace",
    index=False
)

print("✅ تم تنفيذ Extract بنجاح")
print("✅ تم تنفيذ Transform بنجاح")
print("✅ تم تنفيذ Load بنجاح")
print("🎉 تم رفع التحليلات النهائية إلى MySQL بنجاح")