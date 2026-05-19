import logging
from pythonjsonlogger import jsonlogger

logger = logging.getLogger("order-service")

handler = logging.StreamHandler()

formatter = jsonlogger.JsonFormatter(
    "%(asctime)s %(levelname)s %(message)s"
)

handler.setFormatter(formatter)

logger.addHandler(handler)

logger.setLevel(logging.INFO)