import { defineConfig } from "vitepress";

const enNav = [
  { text: "Home", link: "/" },
  { text: "Getting Started", link: "/getting-started/introduction" },
  { text: "Architecture", link: "/architecture/overview" },
  { text: "Guides", link: "/guides/" },
  { text: "API Reference", link: "/api/" },
];

const enSidebar = [
  {
    text: "Getting Started",
    items: [
      { text: "Introduction", link: "/getting-started/introduction" },
      { text: "Installation", link: "/getting-started/installation" },
      { text: "Your First Project", link: "/getting-started/first-project" },
    ],
  },
  {
    text: "Architecture",
    items: [
      { text: "Overview", link: "/architecture/overview" },
      {
        text: "Modules",
        collapsed: true,
        items: [
          { text: "Engine", link: "/architecture/modules/engine" },
          { text: "GameContext", link: "/architecture/modules/game-context" },
          { text: "SceneManager", link: "/architecture/modules/scene-manager" },
          { text: "SceneLoader", link: "/architecture/modules/scene-loader" },
          { text: "Scene", link: "/architecture/modules/scene" },
          { text: "World", link: "/architecture/modules/world" },
          { text: "ResourceManager", link: "/architecture/modules/resource-manager" },
          { text: "InputManager", link: "/architecture/modules/input-manager" },
          { text: "AudioManager", link: "/architecture/modules/audio-manager" },
          { text: "CameraManager", link: "/architecture/modules/camera-manager" },
          { text: "Rendering", link: "/architecture/modules/rendering" },
        ],
      },
    ],
  },
  {
    text: "Guides",
    items: [{ text: "Overview", link: "/guides/" }],
  },
  {
    text: "API Reference",
    items: [{ text: "Overview", link: "/api/" }],
  },
];

const esNav = [
  { text: "Inicio", link: "/es/" },
  { text: "Primeros pasos", link: "/es/getting-started/introduction" },
  { text: "Arquitectura", link: "/es/architecture/overview" },
  { text: "Guías", link: "/es/guides/" },
  { text: "Referencia de API", link: "/es/api/" },
];

const esSidebar = [
  {
    text: "Primeros pasos",
    items: [
      { text: "Introducción", link: "/es/getting-started/introduction" },
      { text: "Instalación", link: "/es/getting-started/installation" },
      { text: "Tu primer proyecto", link: "/es/getting-started/first-project" },
    ],
  },
  {
    text: "Arquitectura",
    items: [
      { text: "Descripción general", link: "/es/architecture/overview" },
      {
        text: "Módulos",
        collapsed: true,
        items: [
          { text: "Engine", link: "/es/architecture/modules/engine" },
          { text: "GameContext", link: "/es/architecture/modules/game-context" },
          { text: "SceneManager", link: "/es/architecture/modules/scene-manager" },
          { text: "SceneLoader", link: "/es/architecture/modules/scene-loader" },
          { text: "Scene", link: "/es/architecture/modules/scene" },
          { text: "World", link: "/es/architecture/modules/world" },
          { text: "ResourceManager", link: "/es/architecture/modules/resource-manager" },
          { text: "InputManager", link: "/es/architecture/modules/input-manager" },
          { text: "AudioManager", link: "/es/architecture/modules/audio-manager" },
          { text: "CameraManager", link: "/es/architecture/modules/camera-manager" },
          { text: "Renderizado", link: "/es/architecture/modules/rendering" },
        ],
      },
    ],
  },
  {
    text: "Guías",
    items: [{ text: "Descripción general", link: "/es/guides/" }],
  },
  {
    text: "Referencia de API",
    items: [{ text: "Descripción general", link: "/es/api/" }],
  },
];

export default defineConfig({
  title: "Astra 2D",
  description: "A modular 2D game engine built with Lua and LÖVE.",

  locales: {
    root: {
      label: "English",
      lang: "en",
      themeConfig: {
        nav: enNav,
        sidebar: enSidebar,
      },
    },
    es: {
      label: "Español",
      lang: "es",
      link: "/es/",
      title: "Astra 2D",
      description: "Un motor de juego 2D modular creado con Lua y LÖVE.",
      themeConfig: {
        nav: esNav,
        sidebar: esSidebar,
      },
    },
  },

  themeConfig: {
    search: {
      provider: "local",
    },
    socialLinks: [
      {
        icon: "github",
        link: "https://github.com/Damet24/lua_engine",
      },
    ],
  },
});
