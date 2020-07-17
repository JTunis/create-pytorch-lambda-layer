try:
    import unzip_requirements
except ImportError:
    pass
import torch


def main(event, context):
    """Entry point for Lambda."""
    tensor = torch.rand((2, 5))
    print(tensor)
