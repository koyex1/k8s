using products.Models;
using products.Data;
using StackExchange.Redis;
using System.Text.Json;

namespace products.Services;

public class ProductService
{
    private readonly Db _db;
    private readonly IDatabase _redis;

    public ProductService(Db db, IConnectionMultiplexer redis)
    {
        _db = db;
        _redis = redis.GetDatabase();
    }

    public async Task AddProduct(Product p)
    {
        using var conn = _db.GetConnection();
        await conn.OpenAsync();

        var cmd = new Npgsql.NpgsqlCommand(
            "INSERT INTO products(name, price) VALUES(@name, @price)", conn);

        cmd.Parameters.AddWithValue("name", p.Name);
        cmd.Parameters.AddWithValue("price", p.Price);

        await cmd.ExecuteNonQueryAsync();

        // invalidate cache
        await _redis.KeyDeleteAsync("products");
    }

    public async Task<List<Product>> GetProducts()
    {
        var cached = await _redis.StringGetAsync("products");

        if (!cached.IsNullOrEmpty)
            return JsonSerializer.Deserialize<List<Product>>(cached!)!;

        var list = new List<Product>();

        using var conn = _db.GetConnection();
        await conn.OpenAsync();

        var cmd = new Npgsql.NpgsqlCommand("SELECT id, name, price FROM products", conn);
        var reader = await cmd.ExecuteReaderAsync();

        while (await reader.ReadAsync())
        {
            list.Add(new Product
            {
                Id = reader.GetInt32(0),
                Name = reader.GetString(1),
                Price = reader.GetDecimal(2)
            });
        }

        await _redis.StringSetAsync(
            "products",
            JsonSerializer.Serialize(list),
            TimeSpan.FromMinutes(5)
        );

        return list;
    }
}