// Stremio Add-on for Arabic & Egyptian Torrents
const { addonBuilder } = require("stremio-addon-sdk");
const express = require("express");
const cors = require("cors");
const axios = require("axios");
const cheerio = require("cheerio");
const parseTorrent = require("parse-torrent");
const NodeCache = require("node-cache");

// Create cache with 1-hour TTL
const contentCache = new NodeCache({ stdTTL: 3600 });

// Define content sources
const SOURCES = {
  DOWNVOD: "https://www.downvod.com/",
  AKSV: "https://ak.sv/",
  EGYBEST: "https://egybest.onl/",
  ARAB_TORRENTS: "https://www.arab-torrents.com/"
};

// Define the add-on manifest
const manifest = {
  id: "org.arabictorrents.stremio",
  version: "1.0.0",
  name: "Arabic & Egyptian Torrents",
  description: "Stremio add-on for Arabic and Egyptian torrents from DownVod, AK.SV, EgyBest, and Arab Torrents",
  resources: ["catalog", "stream", "meta"],
  types: ["movie", "series"],
  catalogs: [
    {
      type: "movie",
      id: "arabic.movies",
      name: "Arabic Movies",
      extra: [
        { name: "genre", options: ["Drama", "Comedy", "Action", "Romance", "Historical", "Egyptian", "Lebanese", "Gulf"], isRequired: false },
        { name: "search", isRequired: false },
        { name: "skip", isRequired: false }
      ]
    },
    {
      type: "series",
      id: "arabic.series",
      name: "Arabic Series",
      extra: [
        { name: "genre", options: ["Drama", "Comedy", "Romance", "Historical", "Ramadan", "Egyptian", "Syrian", "Gulf"], isRequired: false },
        { name: "search", isRequired: false },
        { name: "skip", isRequired: false }
      ]
    }
  ],
  background: "https://i.imgur.com/F9Vd3QI.jpg",
  logo: "https://i.imgur.com/mZJjQYD.png",
  idPrefixes: ["ar_"]
};

// Create the add-on builder
const addon = new addonBuilder(manifest);

// Function to scrape and parse content from sources (implement similar for other sources)
async function scrapeDownVod(type) {
  try {
    const url = type === "movie" ? `${SOURCES.DOWNVOD}category/movies/` : `${SOURCES.DOWNVOD}category/series/`;
    const response = await axios.get(url);
    const $ = cheerio.load(response.data);
    
    const items = [];
    $('.post-item').each((index, element) => {
      const title = $(element).find('.post-title a').text().trim();
      const pageUrl = $(element).find('.post-title a').attr('href');
      const poster = $(element).find('img').attr('src');
      
      items.push({
        id: `downvod_${title.replace(/\s+/g, '_')}`,
        type,
        name: title,
        poster,
        pageUrl,
      });
    });
    
    return items;
  } catch (error) {
    console.error(`Error scraping DownVod: ${error.message}`);
    return [];
  }
}

// Catalog Handler
addon.defineCatalogHandler(async ({ type, id }) => {
  console.log("Catalog request:", type, id);
  let items = await scrapeDownVod(type);
  return { metas: items.map(item => ({ id: item.id, type: item.type, name: item.name, poster: item.poster })) };
});

// Express server setup
const app = express();
app.use(cors());
app.use(express.json());
app.get("/manifest.json", (req, res) => res.json(manifest));
app.get("/configure", (req, res) => res.json({ success: true }));
app.use("/stremio", addon.getInterface());

const PORT = process.env.PORT || 7000;
app.listen(PORT, () => console.log(`Arabic Torrents Stremio Add-on running on port ${PORT}`));
