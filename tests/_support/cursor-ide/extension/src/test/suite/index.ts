import * as path from 'path';
import Mocha from 'mocha';
import { glob } from 'glob';

export async function run(): Promise<void> {
    // Create the mocha test
    const mocha = new Mocha({
        ui: 'tdd',
        color: true,
        timeout: 120000 // 2 minute timeout for agent interactions
    });

    const testsRoot = path.resolve(__dirname, '.');
    const testMode = process.env.CURSOR_TEST_MODE;

    let pattern: string;
    if (testMode === 'prompt') {
        pattern = '**/prompt.test.js';
    } else if (testMode === 'discover') {
        pattern = '**/discover.test.js';
    } else {
        // Run all tests by default
        pattern = '**/**.test.js';
    }

    console.log(`Test mode: ${testMode || 'all'}, pattern: ${pattern}`);

    const files = await glob(pattern, { cwd: testsRoot });
    console.log(`Found ${files.length} test files: ${files.join(', ')}`);

    // Add files to the test suite
    files.forEach((f: string) => mocha.addFile(path.resolve(testsRoot, f)));

    return new Promise((resolve, reject) => {
        try {
            // Run the mocha test
            mocha.run((failures: number) => {
                if (failures > 0) {
                    reject(new Error(`${failures} tests failed.`));
                } else {
                    resolve();
                }
            });
        } catch (err) {
            console.error(err);
            reject(err);
        }
    });
}
