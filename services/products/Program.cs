using Serilog;
using products.Data;
using products.Services;
using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

// Logging → stdout (Promtail will scrape)
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateLogger();

builder.Host.UseSerilog();

// Redis
builder.Services.AddSingleton<IConnectionMultiplexer>(
    ConnectionMultiplexer.Connect(builder.Configuration["Redis:ConnectionString"])
);

// DB + services
builder.Services.AddSingleton<Db>();
builder.Services.AddScoped<ProductService>();

builder.Services.AddControllers();

var app = builder.Build();

app.MapControllers();

app.Run();