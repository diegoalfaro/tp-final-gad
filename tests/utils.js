import path from "path";
import fs from "fs/promises";
import pLimit from "p-limit";

import { concurrencyPromises, imagesDirectoryPath } from "./config.js";
import { getNameFromImage } from "./lens.js";

export const getFileData = (filepath) => fs.readFile(filepath);

export const getFileList = (dirpath) => fs.readdir(dirpath);

export const writeToFile = (filePath, ...contents) =>
  fs.writeFile(filePath, `${contents.join("")}`, {
    flag: "a",
  });

const concurrencyLimiter = pLimit(concurrencyPromises);

export const getImageNamesFromFileList = async (fileList, callback) => {
  const filePromises = fileList.map(async (fileName) => {
    return concurrencyLimiter(async () => {
      const filePath = path.join(imagesDirectoryPath, fileName);
      const imageData = await getFileData(filePath);
      const imageName = await getNameFromImage(imageData);

      await callback({ filePath, fileName, imageData, imageName });

      return imageName;
    });
  });

  const result = await Promise.allSettled(filePromises);
  return result;
};

export const getImageNamesFromPages = async (
  pages,
  itemsCallback,
  beforePageCallback,
  afterPageCallback
) => {
  for (let pageName in pages) {
    const pageItems = pages[pageName];
    beforePageCallback({ pageName, pageItems });
    const result = await getImageNamesFromFileList(pageItems, itemsCallback);
    afterPageCallback({ pageName, pageItems, result });
  }
};

export const getFilenameData = (fileName) => {
  const {
    groups: { name, number },
  } = /(?<name>[^\d]+)_(?<number>[\d]+)\.jpg/gmu.exec(fileName);
  return { name, number };
};

export const getFilePages = (fileList) => {
  const pages = [...fileList];

  pages.sort((a, b) => {
    const { name: name_A, number: number_A } = getFilenameData(a);
    const { name: name_B, number: number_B } = getFilenameData(b);

    if (name_A < name_B) {
      return -1;
    }

    if (name_A == name_B) {
      return parseInt(number_A) < parseInt(number_B) ? -1 : 1;
    }

    return 1;
  });

  return pages.group((fileName) => {
    const { name } = getFilenameData(fileName);
    return name;
  });
};

export const levenshteinDistance = (str1 = "", str2 = "") => {
  const track = Array(str2.length + 1)
    .fill(null)
    .map(() => Array(str1.length + 1).fill(null));
  for (let i = 0; i <= str1.length; i += 1) {
    track[0][i] = i;
  }
  for (let j = 0; j <= str2.length; j += 1) {
    track[j][0] = j;
  }
  for (let j = 1; j <= str2.length; j += 1) {
    for (let i = 1; i <= str1.length; i += 1) {
      const indicator = str1[i - 1] === str2[j - 1] ? 0 : 1;
      track[j][i] = Math.min(
        track[j][i - 1] + 1, // deletion
        track[j - 1][i] + 1, // insertion
        track[j - 1][i - 1] + indicator // substitution
      );
    }
  }
  return track[str2.length][str1.length];
};
