FROM public.ecr.aws/lambda/python:3.11

# Copiamos el código de la función
COPY lambda_check.py .

# Instalamos dependencias
RUN pip install requests boto3 --target .

# Definimos el handler
CMD ["lambda_check.lambda_handler"]
