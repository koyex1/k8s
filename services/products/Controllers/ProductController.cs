using Microsoft.AspNetCore.Mvc;
using products.Models;
using products.Services;

namespace products.Controllers;

[ApiController]
[Route("products")] // GET & POST /products
public class ProductsController : ControllerBase
{
    private readonly ProductService _svc;
    private readonly ILogger<ProductsController> _log;

    public ProductsController(ProductService svc, ILogger<ProductsController> log)
    {
        _svc = svc;
        _log = log;
    }

    private string? GetUserId() => Request.Headers["X-User-Id"];

    [HttpPost]
    public async Task<IActionResult> Add(Product p)
    {
        var userId = GetUserId();

        if (string.IsNullOrEmpty(userId))
            return Unauthorized("Missing auth headers");


        _log.LogInformation("product_add user={UserId} name={Name}", GetUserId(), p.Name);

        await _svc.AddProduct(p);

        return Ok("Product added");
    }

    [HttpGet]
    public async Task<IActionResult> List()
    {
        // Log all headers
         Console.WriteLine("\n=== ALL HEADERS ===");
        foreach (var header in Request.Headers)
        {
            Console.WriteLine($"{header.Key}: {header.Value}");
            _log.LogInformation("Header: {Key} = {Value}", header.Key, header.Value);
        }
        Console.WriteLine("==================\n");

        var userId = GetUserId();

        if (string.IsNullOrEmpty(userId))
            return Unauthorized("Missing auth headers");

        var products = await _svc.GetProducts();

        _log.LogInformation("product_list user={UserId}", GetUserId());

        return Ok(products);
    }
}