# [<img src="https://github.com/wdotv/art/blob/HEAD/w-logo.svg" alt="W" width="64" />](https://github.com/wdotv)

**W** is a modular, full-featured,
developer-first web application framework for [V](https://vlang.io),
with built-in auth & RBAC,
and an expressive ORM inspired by [Laravel](https://laravel.com)'s Eloquent.

---

## 📦 Installation

> **Requirements:** V 0.4.x or later

- Via V (Recommended)

```sh
v install --git https://github.com/siguici/w
```

- Install from source:

```bash
mkdir -p ${VMODULES:-$HOME/.vmodules}
git clone --depth=1 https://github.com/siguici/w ${VMODULES:-$HOME/.vmodules}/w
```

- Import directly:

```v
import w
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
import w.orm { Model }

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

Stay tuned via: [https://github.com/siguici/w](https://github.com/siguici/w)

---

## 🧠 Philosophy

W draws inspiration from frameworks like Laravel, AdonisJS, and Django,
but focuses on the simplicity, performance, and native nature of V.

Its goal is to offer a clean, expressive, and modular foundation
for building web applications entirely in V.

---

## 🪪 License

MIT © [@siguici](https://github.com/siguici)
