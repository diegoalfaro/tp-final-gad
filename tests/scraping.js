import "./polyfills.js"

import {
  artworksFile,
  imagesDirectoryPath,
  scrapingReportFile,
  writeItem,
  writePageHeader,
} from "./config.js";

import {
  getFileList,
  getFilePages,
  getImageNamesFromPages,
  writeToFile,
} from "./utils.js";

const itemsCallback = ({ fileName, imageName }) =>
  writeToFile(artworksFile, writeItem({ fileName, imageName }), "\n");

const beforePageCallback = ({ pageName }) =>
  writeToFile(artworksFile, writePageHeader({ pageName }), "\n");

const afterPageCallback = async ({ pageName, result }) =>
  writeToFile(
    scrapingReportFile,
    `Results for page ${pageName}:`,
    " ",
    JSON.stringify(result),
    "\n"
  );

const filesInDirectory = await getFileList(imagesDirectoryPath);
const pages = getFilePages(filesInDirectory);

getImageNamesFromPages(
  pages,
  itemsCallback,
  beforePageCallback,
  afterPageCallback
)
  .then(() => {
    console.log("Finished OK");
  })
  .catch((reason) => {
    console.error("Finished with error, reason:", reason);
  });
