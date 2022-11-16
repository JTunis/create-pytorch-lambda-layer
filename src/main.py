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


def main(event, context):
    s3 = boto3.client('s3')

    bucket = 'data-hello-world-car-gra-serverlessdeploymentbuck-1lieokb7ux9p9'

    key = 'simple-model'

    location = '/tmp/simple-model'
    s3.download_file(bucket, key, location)
    
    model_ft = torch.load(location)
    
    # switch the model to evaluation mode to make dropout and batch norm work in eval mode
    model_ft.eval()
    
    body = json.loads(event['body'])
    
    base64_encoded_image = body['image']
    
    img_path = '/tmp/img.jpg'
    
    with open(img_path, "wb") as file:
        print(file.write(base64.b64decode(base64_encoded_image)))

    image = read_image(img_path)
    # print('image')
    # print(image)
    image = loader(image).float()
    image = torch.autograd.Variable(image, requires_grad=True)
    image = image.unsqueeze(0)
    output = model_ft(image)
    conf, predicted = torch.max(output.data, 1)

    print('confidence:', conf.item())
    print('predicted:', predicted.item())
    
    # map output to label enum
    predictionMap = {0: 'Excellent', 1: 'Good', 2: 'Average'} 
    grade = predictionMap[predicted.item()]
    print('grade', grade)  

    
    # TODO save output to S3
    # s3.put(output, 's3-url')

    body = {
        "input": event,
        "output": grade
    }

    response = {"statusCode": 200, "body": json.dumps(body)}
    
    print(response)
    
    return response
    
