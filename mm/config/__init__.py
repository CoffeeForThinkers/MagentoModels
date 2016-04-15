import os

IS_DEBUG = bool(int(os.environ.get('DEBUG', '0')))

FMT_DATETIME_STD = '%Y-%m-%d %H:%M:%S'
