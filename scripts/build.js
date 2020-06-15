const fs = require('fs');
const path = require('path');
const nunjucks = require('nunjucks');

const package_config = require(path.join(process.env.INIT_CWD, 'package.json'));

nunjucks.configure({ autoescape: true });

(async () => {
  try {
    const template_dir = path.join(process.env.INIT_CWD, 'meta');
    const files = await fs.promises.readdir(template_dir);

    for (const file of files) {
      const file_path = path.join(template_dir, file);

      await fs.promises.writeFile(
        path.join(process.env.INIT_CWD, path.parse(file).name),
        nunjucks.render (file_path, package_config),
        (err) => {
          if (err) {
            console.log(`error rendering ${file}: ${err}`);
          }
        }
      );
    }
  } catch(err) {
    console.log(err);
  }
})();
