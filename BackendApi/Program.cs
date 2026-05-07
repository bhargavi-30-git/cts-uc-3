using Azure.Storage.Blobs;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});
builder.Services.AddControllers();
var app = builder.Build();
app.UseCors("AllowFrontend");
app.MapControllers();
app.Run();