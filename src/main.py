try:
    import unzip_requirements
except ImportError:
    pass
import torch
import torchvision
import torchvision.transforms as transforms
from torchvision.io import read_image

import boto3
import json
import base64

# transforms for the input image
loader = transforms.Compose([transforms.ToPILImage(),
    transforms.Resize((400, 400)),
                                transforms.ToTensor(),
                                transforms.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5))])


s3 = boto3.client('s3')

bucket = 'data-hello-world-car-gra-serverlessdeploymentbuck-1lieokb7ux9p9'
key = 'model/prod-model'
location = '/tmp/model'
s3.download_file(bucket, key, location)

model_ft = torch.load(location, map_location=torch.device('cpu'))
    
# switch the model to evaluation mode to make dropout and batch norm work in eval mode
model_ft.eval()

def main(event, context):
    body = json.loads(event['body'])
    
    base64_encoded_image = body
    
    img_path = '/tmp/img.jpg'
    
    with open(img_path, "wb") as file:
        print(file.write(base64.b64decode(base64_encoded_image)))

    image = read_image(img_path)
    image = loader(image).float()
    image = torch.autograd.Variable(image, requires_grad=True)
    image = image.unsqueeze(0)
    output = model_ft(image)
    conf, predicted = torch.max(output.data, 1)

    car_class = predicted.item()

    print('confidence:', conf.item())
    print('car_class:', car_class)
    
    mapClassToLabel = {0: 'Excellent', 1: 'Good', 2: 'Average'} 
    grade = mapClassToLabel[car_class]
    print('grade', grade)  
    
    mapClassToPrice = {0: 1500, 1: 1200, 2: 900} 
    price = mapClassToPrice[car_class]

    
    # TODO save output to S3
    # s3.put(output, 's3-url')

    body = {
        "input": event,
        "output": { "grade": grade, "price": price }
    }

    response = {"statusCode": 200, "body": json.dumps(body), 'headers': {
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        }}
    
    print(response)
    
    return response
    
