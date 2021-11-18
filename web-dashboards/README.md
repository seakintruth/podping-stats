# README for the Favicon Package

This package was generated with [RealFaviconGenerator](https://realfavicongenerator.net/) [v0.16](https://realfavicongenerator.net/change_log#v0.16)

## Install instructions

To install this package:

Extract this package in the root of your web site. If your site is <code>http://www.example.com</code>, you should be able to access a file named <code>http://www.example.com/favicon.ico</code>.

Insert the following code in the `head` section of your pages:
```
    <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png?v=1">
    <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png?v=1">
    <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png?v=1">
    <link rel="manifest" href="/site.webmanifest?v=1">
    <link rel="mask-icon" href="/safari-pinned-tab.svg?v=1" color="#5bbad5">
    <link rel="shortcut icon" href="/favicon.ico?v=1">
    <meta name="msapplication-TileColor" content="#da532c">
    <meta name="theme-color" content="#ffffff">
```

For shiny sites use these tag functions:
```
ui <- fluidPage( 
  tags$head(
    tags$link(rel="apple-touch-icon",href="/apple-touch-icon.png?v=1",sizes="180x180"),
    tags$link(rel="icon",type="image/png",sizes="32x32",href="/favicon-32x32.png?v=1"),
    tags$link(rel="icon", type="image/png", sizes="16x16",href="/favicon-16x16.png?v=1"),
    tags$link(rel="manifest", href="/site.webmanifest?v=1"),
    tags$link(rel="mask-icon", href="/safari-pinned-tab.svg?v=1",color="#5bbad5"),
    tags$link(rel="shortcut icon", href="/favicon.ico?v=1"),
    tags$meta(name="msapplication-TileColor", content="#da532c"),
    tags$meta(name="theme-color", content="#ffffff")
  )
)
```


*Optional* - Check your favicon with the [favicon checker](https://realfavicongenerator.net/favicon_checker)