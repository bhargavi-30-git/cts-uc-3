using Azure.Storage.Blobs;
using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/[controller]")]
public class StorageController : ControllerBase
{
    [HttpGet("list")]
    public async Task<IActionResult> ListFiles()
    {
        var connStr = Environment.GetEnvironmentVariable("AZURE_STORAGE_CONNECTION_STRING");
        var container = Environment.GetEnvironmentVariable("AZURE_STORAGE_CONTAINER_NAME");
        var client = new BlobContainerClient(connStr, container);
        var files = new List<string>();
        await foreach (var blob in client.GetBlobsAsync())
            files.Add(blob.Name);
        return Ok(files);
    }

    [HttpPost("upload")]
    public async Task<IActionResult> UploadFile(IFormFile file)
    {
        var connStr = Environment.GetEnvironmentVariable("AZURE_STORAGE_CONNECTION_STRING");
        var container = Environment.GetEnvironmentVariable("AZURE_STORAGE_CONTAINER_NAME");
        var client = new BlobContainerClient(connStr, container);
        var blobClient = client.GetBlobClient(file.FileName);
        using var stream = file.OpenReadStream();
        await blobClient.UploadAsync(stream, overwrite: true);
        return Ok(new { message = "File uploaded", fileName = file.FileName });
    }
}