import React, { useEffect, useState, useRef } from "react";

const BASE_URL = 'http://localhost:9080';
/*const BASE_URL = 'http://apisix:9080';*/

type User = { id: number; username: string; email: string };
type Product = { id: number; name: string; price: number };
type Cart = { id: string; product_id: number; product_name: string; quantity: number };
type Order = { id: number; user_id: string; username: string; product_id: number; quantity: number; status: string };
type Notification = { type: string; message: string };
type Tab = "products" | "cart" | "orders" | "notifications";

const FONTS = `
  @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;600&family=DM+Sans:wght@300;400;500&display=swap');
`;

const STYLES = `
  ${FONTS}
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: 'DM Sans', sans-serif; background: #0c0c0e; color: #e8e6e1; min-height: 100vh; }

  .app-shell { display: flex; min-height: 100vh; }

  /* SIDEBAR */
  .sidebar {
    width: 240px; min-height: 100vh; background: #111113;
    border-right: 1px solid #1f1f24; display: flex; flex-direction: column;
    position: fixed; left: 0; top: 0; bottom: 0; z-index: 10; padding: 0;
  }
  .sidebar-logo {
    padding: 28px 24px 24px;
    border-bottom: 1px solid #1f1f24;
  }
  .sidebar-logo-text {
    font-family: 'Playfair Display', serif;
    font-size: 22px; font-weight: 600; color: #e8e6e1; letter-spacing: -0.3px;
  }
  .sidebar-logo-sub {
    font-size: 11px; color: #555; letter-spacing: 2px; text-transform: uppercase; margin-top: 2px;
  }
  .sidebar-nav { flex: 1; padding: 16px 12px; }
  .nav-item {
    display: flex; align-items: center; gap: 12px; padding: 11px 12px;
    border-radius: 10px; cursor: pointer; font-size: 14px; font-weight: 400;
    color: #888; transition: all 0.18s; margin-bottom: 2px; border: none;
    background: transparent; width: 100%; text-align: left;
  }
  .nav-item:hover { color: #e8e6e1; background: #1a1a1f; }
  .nav-item.active { color: #e8e6e1; background: #1f1f26; font-weight: 500; }
  .nav-item .nav-icon { font-size: 18px; width: 20px; text-align: center; }
  .nav-badge {
    margin-left: auto; background: #c9a96e; color: #111; font-size: 11px;
    font-weight: 600; padding: 2px 7px; border-radius: 20px; min-width: 20px; text-align: center;
  }
  .sidebar-user {
    padding: 16px; border-top: 1px solid #1f1f24;
  }
  .user-pill {
    display: flex; align-items: center; gap: 10px; padding: 10px 12px;
    border-radius: 10px; background: #1a1a1f;
  }
  .user-avatar {
    width: 32px; height: 32px; border-radius: 50%; background: #c9a96e;
    display: flex; align-items: center; justify-content: center;
    font-size: 13px; font-weight: 600; color: #111; flex-shrink: 0;
  }
  .user-name { font-size: 13px; font-weight: 500; color: #e8e6e1; }
  .user-email { font-size: 11px; color: #555; }

  /* MAIN CONTENT */
  .main { margin-left: 240px; flex: 1; padding: 40px 48px; max-width: calc(100vw - 240px); }

  /* PAGE HEADER */
  .page-header { margin-bottom: 36px; }
  .page-title { font-family: 'Playfair Display', serif; font-size: 32px; font-weight: 400; color: #e8e6e1; }
  .page-subtitle { font-size: 14px; color: #555; margin-top: 4px; }

  /* CARDS */
  .card {
    background: #111113; border: 1px solid #1f1f24; border-radius: 16px;
    padding: 24px; margin-bottom: 12px;
  }
  .card-compact { padding: 16px 20px; }

  /* PRODUCT GRID */
  .product-grid {
    display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px; margin-bottom: 40px;
  }
  .product-card {
    background: #111113; border: 1px solid #1f1f24; border-radius: 16px;
    padding: 20px; transition: border-color 0.2s, transform 0.2s;
    display: flex; flex-direction: column;
  }
  .product-card:hover { border-color: #2a2a32; transform: translateY(-2px); }
  .product-icon {
    width: 44px; height: 44px; border-radius: 12px; background: #1a1a1f;
    display: flex; align-items: center; justify-content: center;
    font-size: 20px; margin-bottom: 16px;
  }
  .product-name { font-size: 15px; font-weight: 500; color: #e8e6e1; margin-bottom: 6px; }
  .product-price { font-size: 22px; font-weight: 600; color: #c9a96e; margin-bottom: 16px; }
  .product-price span { font-size: 13px; font-weight: 400; color: #555; }
  .product-id { font-size: 11px; color: #444; margin-bottom: auto; padding-bottom: 16px; }

  /* BUTTONS */
  .btn {
    display: inline-flex; align-items: center; justify-content: center; gap: 8px;
    padding: 10px 18px; border-radius: 10px; font-family: 'DM Sans', sans-serif;
    font-size: 13px; font-weight: 500; cursor: pointer; transition: all 0.18s;
    border: none; outline: none;
  }
  .btn-gold {
    background: #c9a96e; color: #111; width: 100%;
  }
  .btn-gold:hover { background: #d4b87e; }
  .btn-outline {
    background: transparent; color: #888; border: 1px solid #2a2a32;
  }
  .btn-outline:hover { color: #e8e6e1; border-color: #444; background: #1a1a1f; }
  .btn-ghost {
    background: transparent; color: #c9a96e; border: 1px solid #2a1a00;
    width: 100%;
  }
  .btn-ghost:hover { background: #1a1200; }
  .btn-sm { padding: 7px 14px; font-size: 12px; }
  .btn-danger { background: transparent; color: #c0523c; border: 1px solid #2a1510; }
  .btn-danger:hover { background: #1a0e0a; }

  /* FORM */
  .form-section { margin-bottom: 40px; }
  .section-label {
    font-size: 11px; font-weight: 500; color: #555; letter-spacing: 1.5px;
    text-transform: uppercase; margin-bottom: 16px;
  }
  .form-row { display: flex; gap: 12px; align-items: flex-end; flex-wrap: wrap; }
  .form-group { display: flex; flex-direction: column; gap: 8px; flex: 1; min-width: 160px; }
  .form-label { font-size: 12px; color: #666; }
  .form-input {
    background: #0c0c0e; border: 1px solid #1f1f24; border-radius: 10px;
    padding: 11px 14px; font-family: 'DM Sans', sans-serif; font-size: 14px;
    color: #e8e6e1; outline: none; transition: border-color 0.18s; width: 100%;
  }
  .form-input:focus { border-color: #c9a96e44; }
  .form-input::placeholder { color: #333; }

  /* CART ITEMS */
  .cart-item {
    background: #111113; border: 1px solid #1f1f24; border-radius: 14px;
    padding: 18px 20px; margin-bottom: 10px; display: flex;
    align-items: center; gap: 16px;
  }
  .cart-icon {
    width: 42px; height: 42px; border-radius: 10px; background: #1a1a1f;
    display: flex; align-items: center; justify-content: center;
    font-size: 18px; flex-shrink: 0;
  }
  .cart-info { flex: 1; }
  .cart-product-name { font-size: 15px; font-weight: 500; color: #e8e6e1; }
  .cart-meta { font-size: 12px; color: #555; margin-top: 4px; }
  .cart-qty {
    background: #1a1a1f; border: 1px solid #2a2a32; border-radius: 8px;
    padding: 4px 12px; font-size: 14px; font-weight: 500; color: #888;
  }

  /* ORDERS */
  .order-item {
    background: #111113; border: 1px solid #1f1f24; border-radius: 14px;
    padding: 18px 20px; margin-bottom: 10px; display: flex;
    align-items: center; gap: 16px;
  }
  .order-status {
    padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 500;
  }
  .status-pending { background: #1a1200; color: #c9a96e; border: 1px solid #2a2000; }
  .status-processing { background: #0a1525; color: #5b9bd5; border: 1px solid #0f2035; }
  .status-completed { background: #0a1a10; color: #5db882; border: 1px solid #0f2518; }
  .status-cancelled { background: #1a0e0a; color: #c0523c; border: 1px solid #2a1510; }

  /* NOTIFICATIONS */
  .notif-item {
    background: #111113; border-left: 3px solid #c9a96e; border-radius: 0 14px 14px 0;
    border-top: 1px solid #1f1f24; border-right: 1px solid #1f1f24; border-bottom: 1px solid #1f1f24;
    padding: 16px 20px; margin-bottom: 10px;
  }
  .notif-type { font-size: 11px; color: #c9a96e; font-weight: 500; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 6px; }
  .notif-msg { font-size: 14px; color: #aaa; }

  /* AUTH PAGE */
  .auth-wrap {
    min-height: 100vh; display: flex; align-items: center; justify-content: center;
    background: #0c0c0e; padding: 24px;
  }
  .auth-box { width: 100%; max-width: 400px; }
  .auth-logo {
    text-align: center; margin-bottom: 48px;
  }
  .auth-logo-text {
    font-family: 'Playfair Display', serif; font-size: 36px; font-weight: 400; color: #e8e6e1;
  }
  .auth-logo-sub {
    font-size: 12px; color: #444; letter-spacing: 3px; text-transform: uppercase; margin-top: 6px;
  }
  .auth-tabs {
    display: flex; border-bottom: 1px solid #1f1f24; margin-bottom: 32px;
  }
  .auth-tab {
    flex: 1; padding: 12px; font-size: 14px; font-weight: 400; color: #555;
    cursor: pointer; text-align: center; transition: all 0.18s; border: none;
    background: transparent; font-family: 'DM Sans', sans-serif;
    border-bottom: 2px solid transparent; margin-bottom: -1px;
  }
  .auth-tab.active { color: #e8e6e1; border-bottom-color: #c9a96e; }
  .auth-fields { display: flex; flex-direction: column; gap: 16px; margin-bottom: 24px; }
  .auth-message {
    text-align: center; font-size: 13px; color: #c9a96e; margin-top: 16px;
    min-height: 20px;
  }

  /* TOAST */
  .toast-wrap {
    position: fixed; bottom: 24px; right: 24px; display: flex;
    flex-direction: column; gap: 8px; z-index: 100;
  }
  .toast {
    background: #1a1a1f; border: 1px solid #2a2a32; border-left: 3px solid #c9a96e;
    border-radius: 12px; padding: 14px 18px; font-size: 13px; color: #ccc;
    max-width: 300px; animation: slideIn 0.25s ease;
  }
  @keyframes slideIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }

  /* EMPTY STATE */
  .empty { text-align: center; padding: 60px 20px; color: #444; }
  .empty-icon { font-size: 40px; margin-bottom: 12px; }
  .empty-text { font-size: 15px; }

  /* STATS ROW */
  .stats-row { display: flex; gap: 12px; margin-bottom: 32px; }
  .stat-card {
    background: #111113; border: 1px solid #1f1f24; border-radius: 14px;
    padding: 18px 20px; flex: 1;
  }
  .stat-label { font-size: 11px; color: #555; text-transform: uppercase; letter-spacing: 1.5px; }
  .stat-value { font-size: 28px; font-weight: 600; color: #e8e6e1; margin-top: 6px; }

  /* RESPONSIVE */
  @media (max-width: 768px) {
    .sidebar { width: 0; overflow: hidden; }
    .main { margin-left: 0; padding: 24px 20px; max-width: 100vw; }
    .stats-row { flex-direction: column; }
    .product-grid { grid-template-columns: 1fr 1fr; }
  }

  /* DIVIDER */
  .divider { border: none; border-top: 1px solid #1f1f24; margin: 32px 0; }

  /* SCROLLBAR */
  ::-webkit-scrollbar { width: 4px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb { background: #2a2a32; border-radius: 4px; }
`;

const PRODUCT_EMOJIS = ["🖥", "🎧", "📷", "⌚", "💡", "🎮", "📱", "🖨", "🔋", "🎙"];
function getEmoji(id: number) { return PRODUCT_EMOJIS[id % PRODUCT_EMOJIS.length]; }

function getStatusClass(status: string) {
  if (!status) return "status-pending";
  const s = status.toLowerCase();
  if (s.includes("complet") || s.includes("success")) return "status-completed";
  if (s.includes("cancel")) return "status-cancelled";
  if (s.includes("process")) return "status-processing";
  return "status-pending";
}

type ToastItem = { id: number; text: string };

export default function App() {
  const [activeTab, setActiveTab] = useState<"login" | "register">("login");
  const [loggedIn, setLoggedIn] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const [mainTab, setMainTab] = useState<Tab>("products");
  const [registerForm, setRegisterForm] = useState({ email: "", username: "", password: "" });
  const [loginForm, setLoginForm] = useState({ username: "", password: "" });
  const [productForm, setProductForm] = useState({ name: "", price: "" });
  const [products, setProducts] = useState<Product[]>([]);
  const [cart, setCart] = useState<Cart[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [message, setMessage] = useState("");
  const [toasts, setToasts] = useState<ToastItem[]>([]);
  const toastId = useRef(0);

  const token = localStorage.getItem("token");
  const authHeaders = { "Content-Type": "application/json", Authorization: `Bearer ${token}` };

  const addToast = (text: string) => {
    const id = ++toastId.current;
    setToasts(prev => [...prev, { id, text }]);
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 3500);
  };

  const fetchProducts = async () => {
    try {
      const res = await fetch(`${BASE_URL}/products`, { headers: authHeaders });
      setProducts(await res.json());
    } catch (e) { console.error(e); }
  };

  const fetchCart = async () => {
    try {
      const res = await fetch(`${BASE_URL}/cart`, { headers: authHeaders });
      setCart(await res.json());
    } catch (e) { console.error(e); }
  };

  useEffect(() => {
  if (!loggedIn || !user) return;

  const token = localStorage.getItem("token");

  const controller = new AbortController();

  fetch(`${BASE_URL}/notifications/stream`, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`
    },
    signal: controller.signal
  })
    .then((res) => {
      if (!res.body) return;

      const reader = res.body.getReader();
      const decoder = new TextDecoder();

      const readStream = async () => {
        while (true) {
          const { value, done } = await reader.read();
          if (done) break;

          const chunk = decoder.decode(value, { stream: true });

          chunk.split("\n\n").forEach((line) => {
            if (line.startsWith("data: ")) {
              const json = line.replace("data: ", "").trim();

              try {
                const data = JSON.parse(json);

                if (data.type === "order_processed") {
                  setNotifications((prev) => [data, ...prev]);
                  addToast(data.message || "Order processed!");
                }
              } catch (e) {
                console.error("Invalid SSE data", e);
              }
            }
          });
        }
      };

      readStream();
    })
    .catch((err) => {
      console.error("SSE error:", err);
    });

  return () => controller.abort();
}, [loggedIn, user]);

  useEffect(() => {
    if (loggedIn) { fetchProducts(); fetchCart(); }
  }, [loggedIn]);

  const handleRegister = async () => {
    try {
      const res = await fetch(`${BASE_URL}/register`, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify(registerForm)
      });
      const data = await res.text();
      setMessage(data);
      setActiveTab("login");
    } catch (e) { console.error(e); }
  };

  const handleLogin = async () => {
    try {
      const res = await fetch(`${BASE_URL}/login`, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify(loginForm)
      });
      const data = await res.json();
      localStorage.setItem("token", data.access_token);
      setUser(data.user);
      setLoggedIn(true);
    } catch (e) { console.error(e); }
  };

  const handleAddProduct = async () => {
    if (!productForm.name || !productForm.price) return;
    try {
      await fetch(`${BASE_URL}/products`, {
        method: "POST", headers: authHeaders,
        body: JSON.stringify({ name: productForm.name, price: Number(productForm.price) })
      });
      addToast(`"${productForm.name}" added to catalogue`);
      setProductForm({ name: "", price: "" });
      fetchProducts();
    } catch (e) { console.error(e); }
  };

  const handleAddToCart = async (productId: number) => {
    try {
      const res = await fetch(`${BASE_URL}/cart`, {
        method: "POST", headers: authHeaders,
        body: JSON.stringify({ product_id: productId, quantity: 1 })
      });
      const data = await res.json();
      addToast(data.message || "Added to cart");
      fetchCart();
      setMainTab("cart");
    } catch (e) { console.error(e); }
  };

  const handleCreateOrder = async (item: Cart) => {
    try {
      const res = await fetch(`${BASE_URL}/order`, {
        method: "POST", headers: authHeaders,
        body: JSON.stringify({ user_id: user?.id, username: user?.username, product_id: item.product_id, quantity: item.quantity })
      });
      const data = await res.json();
      setOrders(prev => [data.order, ...prev]);
      addToast("Order placed successfully");
      setMainTab("orders");
    } catch (e) { console.error(e); }
  };

  if (!loggedIn) {
    return (
      <>
        <style>{STYLES}</style>
        <div className="auth-wrap">
          <div className="auth-box">
            <div className="auth-logo">
              <div className="auth-logo-text">Merx</div>
              <div className="auth-logo-sub">Commerce Platform</div>
            </div>
            <div className="auth-tabs">
              <button className={`auth-tab ${activeTab === "login" ? "active" : ""}`} onClick={() => setActiveTab("login")}>Sign in</button>
              <button className={`auth-tab ${activeTab === "register" ? "active" : ""}`} onClick={() => setActiveTab("register")}>Create account</button>
            </div>
            {activeTab === "register" ? (
              <div className="auth-fields">
                <div className="form-group">
                  <label className="form-label">Email address</label>
                  <input className="form-input" placeholder="you@example.com" value={registerForm.email}
                    onChange={e => setRegisterForm({ ...registerForm, email: e.target.value })} />
                </div>
                <div className="form-group">
                  <label className="form-label">Username</label>
                  <input className="form-input" placeholder="handle" value={registerForm.username}
                    onChange={e => setRegisterForm({ ...registerForm, username: e.target.value })} />
                </div>
                <div className="form-group">
                  <label className="form-label">Password</label>
                  <input className="form-input" type="password" placeholder="••••••••" value={registerForm.password}
                    onChange={e => setRegisterForm({ ...registerForm, password: e.target.value })} />
                </div>
                <button className="btn btn-gold" style={{ marginTop: 8 }} onClick={handleRegister}>Create account</button>
              </div>
            ) : (
              <div className="auth-fields">
                <div className="form-group">
                  <label className="form-label">Username</label>
                  <input className="form-input" placeholder="handle" value={loginForm.username}
                    onChange={e => setLoginForm({ ...loginForm, username: e.target.value })} />
                </div>
                <div className="form-group">
                  <label className="form-label">Password</label>
                  <input className="form-input" type="password" placeholder="••••••••" value={loginForm.password}
                    onChange={e => setLoginForm({ ...loginForm, password: e.target.value })} />
                </div>
                <button className="btn btn-gold" style={{ marginTop: 8 }} onClick={handleLogin}>Sign in</button>
              </div>
            )}
            {message && <div className="auth-message">{message}</div>}
          </div>
        </div>
      </>
    );
  }

  const initials = user?.username?.slice(0, 2).toUpperCase() || "U";
  const totalCartItems = cart.reduce((sum, i) => sum + i.quantity, 0);

  const NAV_ITEMS: { key: Tab; label: string; icon: string; badge?: number }[] = [
    { key: "products", label: "Products", icon: "🛍" },
    { key: "cart", label: "Cart", icon: "🛒", badge: totalCartItems || undefined },
    { key: "orders", label: "Orders", icon: "📦", badge: orders.length || undefined },
    { key: "notifications", label: "Notifications", icon: "🔔", badge: notifications.length || undefined },
  ];

  return (
    <>
      <style>{STYLES}</style>
      <div className="app-shell">
        {/* SIDEBAR */}
        <aside className="sidebar">
          <div className="sidebar-logo">
            <div className="sidebar-logo-text">Merx</div>
            <div className="sidebar-logo-sub">Commerce</div>
          </div>
          <nav className="sidebar-nav">
            {NAV_ITEMS.map(item => (
              <button key={item.key} className={`nav-item ${mainTab === item.key ? "active" : ""}`}
                onClick={() => setMainTab(item.key)}>
                <span className="nav-icon">{item.icon}</span>
                {item.label}
                {item.badge ? <span className="nav-badge">{item.badge}</span> : null}
              </button>
            ))}
          </nav>
          <div className="sidebar-user">
            <div className="user-pill">
              <div className="user-avatar">{initials}</div>
              <div>
                <div className="user-name">{user?.username}</div>
                <div className="user-email">{user?.email}</div>
              </div>
            </div>
          </div>
        </aside>

        {/* MAIN */}
        <main className="main">

          {/* PRODUCTS TAB */}
          {mainTab === "products" && (
            <>
              <div className="page-header">
                <div className="page-title">Products</div>
                <div className="page-subtitle">{products.length} items in catalogue</div>
              </div>

              {/* ADD PRODUCT */}
              <div className="form-section">
                <div className="section-label">Add new product</div>
                <div className="card card-compact">
                  <div className="form-row">
                    <div className="form-group">
                      <label className="form-label">Product name</label>
                      <input className="form-input" placeholder="e.g. Wireless Headphones" value={productForm.name}
                        onChange={e => setProductForm({ ...productForm, name: e.target.value })} />
                    </div>
                    <div className="form-group" style={{ maxWidth: 160 }}>
                      <label className="form-label">Price ($)</label>
                      <input className="form-input" type="number" placeholder="0.00" value={productForm.price}
                        onChange={e => setProductForm({ ...productForm, price: e.target.value })} />
                    </div>
                    <button className="btn btn-gold" style={{ width: "auto", flexShrink: 0, alignSelf: "flex-end" }}
                      onClick={handleAddProduct}>
                      + Add Product
                    </button>
                  </div>
                </div>
              </div>

              {/* PRODUCT GRID */}
              <div className="section-label">Catalogue</div>
              {products.length === 0 ? (
                <div className="empty"><div className="empty-icon">🛍</div><div className="empty-text">No products yet — add one above</div></div>
              ) : (
                <div className="product-grid">
                  {products.map(product => (
                    <div key={product.id} className="product-card">
                      <div className="product-icon">{getEmoji(product.id)}</div>
                      <div className="product-name">{product.name}</div>
                      <div className="product-price">${product.price.toFixed(2)}</div>
                      <div className="product-id">ID #{product.id}</div>
                      <button className="btn btn-gold btn-sm" onClick={() => handleAddToCart(product.id)}>
                        Add to Cart
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </>
          )}

          {/* CART TAB */}
          {mainTab === "cart" && (
            <>
              <div className="page-header">
                <div className="page-title">Cart</div>
                <div className="page-subtitle">{cart.length} item{cart.length !== 1 ? "s" : ""} · {totalCartItems} units total</div>
              </div>
              {cart.length === 0 ? (
                <div className="empty"><div className="empty-icon">🛒</div><div className="empty-text">Your cart is empty</div></div>
              ) : (
                cart.map(item => (
                  <div key={item.id} className="cart-item">
                    <div className="cart-icon">{getEmoji(item.product_id)}</div>
                    <div className="cart-info">
                      <div className="cart-product-name">{item.product_name || "Unknown product"}</div>
                      <div className="cart-meta">Product #{item.product_id} · Cart #{item.id}</div>
                    </div>
                    <div className="cart-qty">×{item.quantity}</div>
                    <button className="btn btn-ghost btn-sm" style={{ width: "auto" }}
                      onClick={() => handleCreateOrder(item)}>
                      Place Order
                    </button>
                  </div>
                ))
              )}
            </>
          )}

          {/* ORDERS TAB */}
          {mainTab === "orders" && (
            <>
              <div className="page-header">
                <div className="page-title">Orders</div>
                <div className="page-subtitle">{orders.length} order{orders.length !== 1 ? "s" : ""} placed</div>
              </div>
              {orders.length === 0 ? (
                <div className="empty"><div className="empty-icon">📦</div><div className="empty-text">No orders yet</div></div>
              ) : (
                orders.map(order => (
                  <div key={order.id} className="order-item">
                    <div className="cart-icon">{getEmoji(order.product_id)}</div>
                    <div className="cart-info">
                      <div className="cart-product-name">Order #{order.id}</div>
                      <div className="cart-meta">Product #{order.product_id} · Qty {order.quantity} · {order.username}</div>
                    </div>
                    <span className={`order-status ${getStatusClass(order.status)}`}>
                      {order.status || "Pending"}
                    </span>
                  </div>
                ))
              )}
            </>
          )}

          {/* NOTIFICATIONS TAB */}
          {mainTab === "notifications" && (
            <>
              <div className="page-header">
                <div className="page-title">Notifications</div>
                <div className="page-subtitle">{notifications.length} notification{notifications.length !== 1 ? "s" : ""}</div>
              </div>
              {notifications.length === 0 ? (
                <div className="empty"><div className="empty-icon">🔔</div><div className="empty-text">No notifications yet</div></div>
              ) : (
                notifications.map((n, i) => (
                  <div key={i} className="notif-item">
                    <div className="notif-type">{n.type.replace(/_/g, " ")}</div>
                    <div className="notif-msg">{n.message}</div>
                  </div>
                ))
              )}
            </>
          )}
        </main>
      </div>

      {/* TOASTS */}
      <div className="toast-wrap">
        {toasts.map(t => <div key={t.id} className="toast">{t.text}</div>)}
      </div>
    </>
  );
}