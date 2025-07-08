# daak.nvim - the original postman

> [!WARNING]
> #### 🚧  WORK IN PROGRESS 🚧
> This repo is currently work in progress. Various features may be functionally
> incomplete. And obviously, there will be bugs.

daak.nvim is a simple neovim plugin to make HTTP and GraphQL requests. You don't
have to leave your editor, and you can fully edit, manipulate, inspect request
and responses. The request and response are written in plain text, and can exist
in any buffer, from where you can execute the request. This means, you can have
a collection of requests saved in a file, which you can open and start executing
requests, or you can open up a scratch buffer, type in the request and execute
it.

## Install

### Using Lazy

```lua
{
  {
    "ecthiender/daak.nvim",
    config = function()
      require("daak").setup()
    end,
  },
}
```

## Usage

Create text in any open buffer of HTTP spec format. Check the `test.txt` file
for examples.

Each text group separated by the separator (`---`) is considered a separate
HTTP request object.

To execute a request, place the cursor anywhere inside a HTTP request object,
and press `<leader>dr`.
