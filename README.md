# Viv

**Viv** is a modular, full-featured,
developer-first web application framework for [V](https://vlang.io),
with built-in auth & RBAC,
and an expressive ORM inspired by [Laravel](https://laravel.com)'s Eloquent.

---

## 📦 Installation

> **Requirements:** V 0.4.x or later

- Install via VPM:

```bash
v install siguici.viv
```

- Install from source:

```bash
mkdir -p ${VMODULES:-$HOME/.vmodules}/siguici
git clone --depth=1 https://github.com/siguici/viv ${VMODULES:-$HOME/.vmodules}/siguici/viv
```

- Import directly:

```v
import siguici.viv
```

---

## ✨ Features (WIP)

- 🔐 Authentication & Role-Based Access Control (RBAC)
- 🧠 Expressive ORM with relationships
- 🧱 Schema builder for defining database structure
- 🕸️ Web-native, built on [Veb](https://github.com/vlang/v/tree/HEAD/vlib/veb)

---

## 🧪 Example Usage

```v
import siguici.viv.orm { Model }

struct User {
    Model
    name  string
    email string [unique]
}

fn (u User) posts() []Post {
    return has_many<User, Post>(u, 'user_id')
}
```

---

## 📚 Documentation

Documentation is in progress.

Stay tuned via: [https://github.com/siguici/viv](https://github.com/siguici/viv)

---

## 🧠 Philosophy

Viv draws inspiration from frameworks like Laravel, AdonisJS, and Django,
but focuses on the simplicity, performance, and native nature of V.

Its goal is to offer a clean, expressive, and modular foundation
for building web applications entirely in V.

---

## 🪪 License

MIT © [@siguici](https://github.com/siguici)
