import Config

config :yookassa,
shop_id: System.get_env("SHOP_ID"),
secret_key: System.get_env("YOOKASSA_API"),
api_url: "https://api.yookassa.ru/v3"
