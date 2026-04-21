@RestController
public class RegisterController {

    @PostMapping("/register")
    public String register() {
        return "Registered";
    }
}