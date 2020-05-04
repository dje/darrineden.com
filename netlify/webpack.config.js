const path = require('path');

module.exports = {
    entry: './tracing.js',
    output: {
        path: path.resolve(__dirname, 'site'),
        filename: 'tracing.js'
    }
};
