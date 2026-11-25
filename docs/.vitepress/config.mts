import { defineConfig } from "vitepress";

const enNav = [
  { text: "Home", link: "/" },
  { text: "Getting Started", link: "/getting-started/introduction" },
  { text: "Architecture", link: "/architecture/overview" },
  { text: "Guides", link: "/guides/" },
  { text: "API Reference", link: "/api/" },
  { text: "Examples", link: "/examples/" },
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
    items: [
      { text: "Overview", link: "/guides/" },
      { text: "Scenes", link: "/guides/scenes" },
      { text: "Resources", link: "/guides/resources" },
      { text: "Controls", link: "/guides/input" },
      { text: "Audio", link: "/guides/audio" },
      { text: "Tiled maps", link: "/guides/tiled" },
      { text: "Cameras and viewport", link: "/guides/cameras" },
      { text: "Entities and systems", link: "/guides/ecs" },
    ],
  },
  {
    text: "API Reference",
    items: [
      { text: "Overview", link: "/api/" },
      {
        text: "Modules",
        collapsed: true,
        items: [
          { text: "Engine", link: "/api/engine" },
          { text: "GameContext", link: "/api/game-context" },
          { text: "Scene", link: "/api/scene" },
          { text: "SceneManager", link: "/api/scene-manager" },
          { text: "SceneLoader", link: "/api/scene-loader" },
          { text: "ResourceManager", link: "/api/resource-manager" },
          { text: "Resource definition utilities", link: "/api/resources-utils" },
          { text: "InputManager", link: "/api/input-manager" },
          { text: "AudioManager", link: "/api/audio-manager" },
          { text: "World and components", link: "/api/world" },
          { text: "Events", link: "/api/events" },
          { text: "Physics", link: "/api/physics" },
          { text: "Cameras", link: "/api/camera" },
          { text: "Rendering", link: "/api/rendering" },
          { text: "Tilemaps", link: "/api/tilemap" },
          { text: "Sprite fonts", link: "/api/sprite-font" },
          { text: "Graphics utilities", link: "/api/graphics-utils" },
        ],
      },
    ],
  },
  { text: "Examples", items: [{ text: "Collect", link: "/examples/" }] },
];

const esNav = [
  { text: "Inicio", link: "/es/" },
  { text: "Primeros pasos", link: "/es/getting-started/introduction" },
  { text: "Arquitectura", link: "/es/architecture/overview" },
  { text: "Guías", link: "/es/guides/" },
  { text: "Referencia de API", link: "/es/api/" },
  { text: "Ejemplos", link: "/es/examples/" },
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
    items: [
      { text: "Descripción general", link: "/es/guides/" },
      { text: "Escenas", link: "/es/guides/scenes" },
      { text: "Recursos", link: "/es/guides/resources" },
      { text: "Controles", link: "/es/guides/input" },
      { text: "Audio", link: "/es/guides/audio" },
      { text: "Mapas de Tiled", link: "/es/guides/tiled" },
      { text: "Cámaras y viewport", link: "/es/guides/cameras" },
      { text: "Entidades y sistemas", link: "/es/guides/ecs" },
    ],
  },
  {
    text: "Referencia de API",
    items: [
      { text: "Descripción general", link: "/es/api/" },
      {
        text: "Módulos",
        collapsed: true,
        items: [
          { text: "Engine", link: "/es/api/engine" },
          { text: "GameContext", link: "/es/api/game-context" },
          { text: "Scene", link: "/es/api/scene" },
          { text: "SceneManager", link: "/es/api/scene-manager" },
          { text: "SceneLoader", link: "/es/api/scene-loader" },
          { text: "ResourceManager", link: "/es/api/resource-manager" },
          { text: "Utilidades de recursos", link: "/es/api/resources-utils" },
          { text: "InputManager", link: "/es/api/input-manager" },
          { text: "AudioManager", link: "/es/api/audio-manager" },
          { text: "World y componentes", link: "/es/api/world" },
          { text: "Eventos", link: "/es/api/events" },
          { text: "Física", link: "/es/api/physics" },
          { text: "Cámaras", link: "/es/api/camera" },
          { text: "Renderizado", link: "/es/api/rendering" },
          { text: "Tilemaps", link: "/es/api/tilemap" },
          { text: "Fuentes de sprites", link: "/es/api/sprite-font" },
          { text: "Utilidades gráficas", link: "/es/api/graphics-utils" },
        ],
      },
    ],
  },
  { text: "Ejemplos", items: [{ text: "Collect", link: "/es/examples/" }] },
];

export default defineConfig({
  title: "Astra 2D",
  description: "A modular 2D game engine built with Lua and LÖVE.",
  base: "/Astra2D/",

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
