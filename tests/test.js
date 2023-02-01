import "./polyfills.js";

import fs from "fs";
import { parse } from "csv-parse";

import { testReportFile } from "./config.js";

import { writeToFile } from "./utils.js";

import { getSimilarArtworks, waitInitiation } from "./api.js";

const getCsvRows = (filepath) =>
  new Promise((resolve, reject) => {
    const rows = [];
    fs.createReadStream(filepath)
      .pipe(parse({ delimiter: ",", from_line: 2 }))
      .on("data", (row) => {
        rows.push(row);
      })
      .on("end", () => {
        resolve(rows);
      })
      .on("error", (error) => {
        reject(error);
      });
  });

const csvRows = await getCsvRows("../static/test/artworks.csv");

await waitInitiation();

const promises = csvRows.map(
  async ([artworkId, title, artistName, imageFilepath, testImageFilepath]) => {
    const startTime = Date.now();

    const similarArtworks = await getSimilarArtworks(
      fs.createReadStream(".." + testImageFilepath)
    );

    const endTime = Date.now();

    const milliseconds = Math.floor((endTime - startTime) % 1000);

    const index = similarArtworks.findIndex(({ id }) => id == artworkId);
    const position = index >= 0 ? index + 1 : null;

    return { artworkId, title, position, milliseconds };
  }
);

const promisesResolved = await Promise.allSettled(promises);

const results = {
  first: 0,
  firsts5: 0,
  found: 0,
  failed: 0,
  total: 0,
  firstsPercentage: 0,
  firsts5Percentage: 0,
  foundPercentage: 0,
  failedPercentage: 0,
  failedOverFoundPercentage: 0,
  notFound: 0,
  milliseconds: 0,
  notFoundPercentage: 0,
  notFoundOverFoundRelation: 0,
  millisecondsAverage: 0,
};

for (const promiseSettledResult of promisesResolved) {
  const { status } = promiseSettledResult || {};
  console.log(status);

  if (status == "fulfilled") {
    const { value } = promiseSettledResult || {};
    const { artworkId, title, position, milliseconds } = value || {};

    if (position) {
      if (position == 1) {
        results.first++;
      }
      if (position <= 5) {
        results.firsts5++;
      }
      results.found++;
    } else {
      results.notFound++;
    }
    results.total++;
    results.milliseconds += milliseconds;

    console.log("(Id, Titulo) de la obra: ", artworkId, title);
    console.log("Posicion (lugar en la busqueda):", position);
  }
}

results.firstsPercentage = (results.first / results.total) * 100;
results.firsts5Percentage = (results.firsts5 / results.total) * 100;
results.foundPercentage = (results.found / results.total) * 100;
results.notFoundPercentage = (results.notFound / results.total) * 100;
results.notFoundOverFoundRelation = results.notFound / results.found;
results.millisecondsAverage = results.milliseconds / results.total;

await writeToFile(testReportFile, JSON.stringify(results, null, "\t"));

console.log("Resultado total:", results);
