using Npgsql;

namespace products.Data;

public class Db
{
    private readonly string _conn;

    public Db(IConfiguration config)
    {
        _conn = config.GetConnectionString("Postgres");
    }

    public NpgsqlConnection GetConnection() => new NpgsqlConnection(_conn);
}