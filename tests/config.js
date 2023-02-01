import path from "path";

export const concurrencyPromises = 50;

export const apiBaseUrl = process.env.API_BASEURL || "http://localhost:8085";

export const imagesDirectoryPath = process.env.IMAGES_DIRECTORY_PATH || "../static/images/";
export const testImagesDirectoryPath = process.env.TEST_IMAGES_DIRECTORY_PATH || "../static/test/";
export const testResultsDirectoryPath = process.env.TEST_RESULTS_DIRECTORY_PATH || "./results/test";
export const scrapingResultsDirectoryPath = process.env.SCRAPING_RESULTS_DIRECTORY_PATH || "./results/scraping";

export const resultFilePrefix = `${new Date().toDateString()}_${new Date().toTimeString()}`;

export const artworksFile = path.join(
  scrapingResultsDirectoryPath,
  `${resultFilePrefix}_artworks.sql`
);

export const scrapingReportFile = path.join(
  scrapingResultsDirectoryPath,
  `${resultFilePrefix}_report.log`
);

export const testReportFile = path.join(
  testResultsDirectoryPath,
  `${resultFilePrefix}_report.json`
);

export const writeItem = ({ fileName, imageName }) => {
  const title = imageName ? `'${imageName.replaceAll("'", "''")}'` : null;
  const filename = fileName ? `'${fileName}'` : null;
  return `INSERT INTO artwork (title, artist_id, filename) VALUES (${title}, artistId, ${filename});`;
};

export const writePageHeader = ({ pageName }) =>
  `-- Items for artist ${pageName}:`;
