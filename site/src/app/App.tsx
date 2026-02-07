import { useState } from 'react';
import { motion, useScroll, useTransform } from 'motion/react';
import { FileText, FolderTree, Target, Sparkles, Check, X, AlertCircle, Copy, ArrowDown } from 'lucide-react';

export default function App() {
  const [copied, setCopied] = useState(false);
  const { scrollYProgress } = useScroll();
  const headerY = useTransform(scrollYProgress, [0, 0.1], [0, -20]);

  const installCommand = 'curl -fsSL https://agentfill.dev/install | sh';

  const copyToClipboard = () => {
    const textArea = document.createElement('textarea');
    textArea.value = installCommand;
    textArea.style.position = 'fixed';
    textArea.style.left = '-999999px';
    textArea.style.top = '-999999px';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();
    
    try {
      document.execCommand('copy');
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy:', err);
    } finally {
      document.body.removeChild(textArea);
    }
  };

  const features = [
    {
      icon: FileText,
      title: 'AGENTS.md Support',
      description: 'Agents automatically read AGENTS.md files instead of (or in addition to) their proprietary formats',
      emoji: '📄'
    },
    {
      icon: FolderTree,
      title: 'Nested Precedence',
      description: 'AGENTS.md files in subdirectories apply and layer with proper precedence (closer = higher priority)',
      emoji: '🪺'
    },
    {
      icon: Target,
      title: 'Selective Loading',
      description: 'Only loads relevant AGENTS.md files, not all of them (e.g. to minimize context bloat)',
      emoji: '🎯'
    },
    {
      icon: Sparkles,
      title: 'Shared Skills',
      description: 'Store skills once in .agents/skills/, use across all agents',
      emoji: '🔧'
    }
  ];

  const comparisonData = [
    { agent: 'Claude Code', basic: false, nested: false, selective: false, skills: true },
    { agent: 'Gemini CLI', basic: 'warning', nested: true, selective: false, skills: 'warning' },
    { agent: 'Cursor IDE', basic: true, nested: false, selective: true, skills: true }
  ];

  return (
    <div className="min-h-screen bg-white text-black">
      {/* Hero Section */}
      <motion.section 
        className="relative min-h-screen flex flex-col items-center justify-center px-6 py-20 border-b-4 border-black"
        style={{ y: headerY }}
      >
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6 }}
          className="text-center max-w-6xl mx-auto"
        >
          {/* Icon */}
          <div className="inline-block mb-12">
            <motion.svg
              width="96"
              height="96"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
              strokeLinejoin="round"
              className="text-black"
            >
              <motion.path
                d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z"
                initial={{ pathLength: 0, opacity: 0 }}
                animate={{ pathLength: 1, opacity: 1 }}
                transition={{ 
                  pathLength: { duration: 1.5, ease: "easeInOut", delay: 0.2 },
                  opacity: { duration: 0.3, delay: 0.2 }
                }}
              />
              <motion.path
                d="M20 3v4"
                initial={{ pathLength: 0, opacity: 0 }}
                animate={{ pathLength: 1, opacity: 1 }}
                transition={{ 
                  pathLength: { duration: 0.4, ease: "easeInOut", delay: 1.4 },
                  opacity: { duration: 0.2, delay: 1.4 }
                }}
              />
              <motion.path
                d="M22 5h-4"
                initial={{ pathLength: 0, opacity: 0 }}
                animate={{ pathLength: 1, opacity: 1 }}
                transition={{ 
                  pathLength: { duration: 0.4, ease: "easeInOut", delay: 1.5 },
                  opacity: { duration: 0.2, delay: 1.5 }
                }}
              />
              <motion.path
                d="M4 17v2"
                initial={{ pathLength: 0, opacity: 0 }}
                animate={{ pathLength: 1, opacity: 1 }}
                transition={{ 
                  pathLength: { duration: 0.3, ease: "easeInOut", delay: 1.7 },
                  opacity: { duration: 0.2, delay: 1.7 }
                }}
              />
              <motion.path
                d="M5 18H3"
                initial={{ pathLength: 0, opacity: 0 }}
                animate={{ pathLength: 1, opacity: 1 }}
                transition={{ 
                  pathLength: { duration: 0.3, ease: "easeInOut", delay: 1.8 },
                  opacity: { duration: 0.2, delay: 1.8 }
                }}
              />
            </motion.svg>
          </div>

          {/* Title with staggered animation */}
          <motion.div className="mb-12 py-8">
            <div className="rotate-[-2deg] flex justify-center">
              <div className="flex items-end">
                {/* AGENT */}
                <div className="relative overflow-hidden" style={{ clipPath: 'polygon(-10% -10%, 110% -10%, 110% 110%, -10% 110%)' }}>
                  <motion.div
                    initial={{ width: 0, height: 20 }}
                    animate={{ 
                      width: 'auto',
                      height: [20, 20, 'auto'],
                    }}
                    transition={{
                      width: { delay: 0.3, duration: 0.4, ease: [0.22, 1, 0.36, 1] },
                      height: { delay: 0.7, duration: 0.5, ease: [0.22, 1, 0.36, 1], times: [0, 0, 1] }
                    }}
                    className="bg-black overflow-hidden relative"
                  >
                    <motion.div
                      initial={{ y: '100%' }}
                      animate={{ y: 0 }}
                      transition={{ delay: 0.7, duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
                      className="text-white px-4 text-[clamp(3rem,12vw,9rem)] font-black leading-[0.9] tracking-tighter uppercase whitespace-nowrap"
                    >
                      AGENT
                    </motion.div>
                  </motion.div>
                </div>
                
                {/* FILL */}
                <div className="relative overflow-hidden" style={{ clipPath: 'polygon(-10% -10%, 110% -10%, 110% 110%, -10% 110%)' }}>
                  <motion.div
                    initial={{ width: 0, height: 20 }}
                    animate={{ 
                      width: 'auto',
                      height: [20, 20, 'auto'],
                    }}
                    transition={{
                      width: { delay: 0.3, duration: 0.4, ease: [0.22, 1, 0.36, 1] },
                      height: { delay: 0.7, duration: 0.5, ease: [0.22, 1, 0.36, 1], times: [0, 0, 1] }
                    }}
                    className="bg-yellow-400 overflow-hidden relative"
                  >
                    <motion.div
                      initial={{ y: '100%' }}
                      animate={{ y: 0 }}
                      transition={{ delay: 0.7, duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
                      className="text-black px-4 text-[clamp(3rem,12vw,9rem)] font-black leading-[0.9] tracking-tighter uppercase whitespace-nowrap"
                    >
                      FILL
                    </motion.div>
                  </motion.div>
                </div>
              </div>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6, duration: 0.6 }}
            className="max-w-3xl mx-auto mb-16"
          >
            <p className="text-xl md:text-2xl mb-4 leading-tight">
              A <span className="bg-yellow-400 px-1 font-bold">"polyfill"</span> that standardizes{' '}
              <a 
                href="https://agents.md" 
                className="font-bold border-b-4 border-black hover:bg-yellow-400 transition-colors"
                target="_blank"
                rel="noopener noreferrer"
              >
                AGENTS.md
              </a> configuration and{' '}
              <a 
                href="https://agentskills.io" 
                className="font-bold border-b-4 border-black hover:bg-yellow-400 transition-colors whitespace-nowrap"
                target="_blank"
                rel="noopener noreferrer"
              >
                Agent Skills
              </a> support for major AI agents.
            </p>
          </motion.div>

          {/* Install command */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7, duration: 0.6 }}
            className="mb-16 max-w-4xl mx-auto"
          >
            <div className="border-4 border-black p-6 bg-white shadow-[8px_8px_0px_0px_rgba(0,0,0,1)]">
              <div className="flex items-center justify-between gap-4 flex-wrap">
                <code className="text-sm md:text-base font-mono flex-1 text-left break-all">
                  {installCommand}
                </code>
                <motion.button
                  whileHover={{ scale: 1.05, x: 2, y: 2 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={copyToClipboard}
                  className="flex-shrink-0 bg-yellow-400 hover:bg-yellow-300 border-4 border-black px-6 py-3 font-black uppercase transition-colors flex items-center gap-2 shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
                >
                  {copied ? (
                    <>
                      <Check className="w-5 h-5" strokeWidth={3} />
                      <span>Copied!</span>
                    </>
                  ) : (
                    <>
                      <Copy className="w-5 h-5" strokeWidth={3} />
                      <span>Copy</span>
                    </>
                  )}
                </motion.button>
              </div>
            </div>
          </motion.div>

          {/* Quick facts */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.8, duration: 0.6 }}
            className="flex flex-wrap gap-6 justify-center text-sm uppercase font-bold"
          >
            {['No (re)build step', 'Simple and portable', 'Universal format'].map((text, i) => (
              <motion.div
                key={text}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.8 + i * 0.1 }}
                className="flex items-center gap-2"
              >
                <div className="w-6 h-6 bg-black flex items-center justify-center">
                  <Check className="w-4 h-4 text-yellow-400" strokeWidth={3} />
                </div>
                <span>{text}</span>
              </motion.div>
            ))}
          </motion.div>
        </motion.div>

        {/* Scroll indicator */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.2 }}
          className="absolute bottom-10"
        >
          <motion.div
            animate={{ y: [0, 12, 0] }}
            transition={{ repeat: Infinity, duration: 1.5, ease: "easeInOut" }}
          >
            <ArrowDown className="w-8 h-8" strokeWidth={3} />
          </motion.div>
        </motion.div>
      </motion.section>

      {/* Features Section */}
      <section className="relative py-24 px-6 bg-black text-white">
        <div className="max-w-7xl mx-auto">
          <motion.div
            initial={{ opacity: 0, x: -50 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="mb-20"
          >
            <h2 className="text-[clamp(2.5rem,8vw,6rem)] font-black uppercase leading-none mb-4">
              Why
              <br />
              <span className="bg-yellow-400 text-black px-4 inline-block rotate-1">agentfill?</span>
            </h2>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {features.map((feature, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 40 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.1, duration: 0.6 }}
                className="border-4 border-white p-8 bg-black hover:bg-white hover:text-black transition-colors group"
              >
                <div className="flex items-start gap-4 mb-4">
                  <div className="text-5xl">{feature.emoji}</div>
                  <div className="flex-1">
                    <h3 className="text-2xl font-black uppercase mb-3 leading-tight">{feature.title}</h3>
                  </div>
                </div>
                <p className="text-lg leading-relaxed">{feature.description}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Philosophy Section */}
      <section className="relative py-24 px-6 border-b-4 border-black">
        <div className="max-w-6xl mx-auto">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="mb-16"
          >
            <h2 className="text-[clamp(2.5rem,8vw,5rem)] font-black uppercase leading-none mb-8">
              <span className="inline-block -rotate-2">Philosophy</span>
            </h2>
            <p className="text-2xl md:text-3xl font-bold leading-tight max-w-4xl">
              AI coding agents <span className="bg-yellow-400 px-2">shouldn't fragment your configuration</span>.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {[
              { title: 'Universal format', desc: 'Write AGENTS.md once, use it across major AI agents (Claude Code, Gemini CLI)' },
              { title: 'Standard locations', desc: '.agents/ and AGENTS.md files in predictable places, not scattered proprietary formats' },
              { title: 'No rebuild step', desc: 'Edit AGENTS.md files, they just work. No commands to run after changes.' },
              { title: 'Native behavior', desc: "Leverage each agent's built-in features (hot reload, skill discovery, etc.)" },
              { title: 'Simple and portable', desc: 'Shell scripts only. Works everywhere with no dependencies.' },
            ].map((item, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, x: index % 2 === 0 ? -30 : 30 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.1, duration: 0.5 }}
                className="border-l-4 border-black pl-6 py-4"
              >
                <h4 className="text-xl font-black uppercase mb-2">{item.title}</h4>
                <p className="text-lg leading-relaxed">{item.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Comparison Table */}
      <section className="relative py-24 px-6 bg-black text-white">
        <div className="max-w-6xl mx-auto">
          <motion.h2
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-[clamp(2rem,6vw,4rem)] font-black uppercase leading-none mb-16"
          >
            Native Support
            <br />
            <span className="bg-yellow-400 text-black px-4 inline-block rotate-1">vs</span>
            <br />
            Agentfill
          </motion.h2>

          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="border-4 border-white overflow-hidden"
          >
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b-4 border-white bg-yellow-400 text-black">
                    <th className="px-6 py-4 text-left font-black uppercase">Agent</th>
                    <th className="px-6 py-4 text-center font-black uppercase">📄 Basic</th>
                    <th className="px-6 py-4 text-center font-black uppercase"> Nested</th>
                    <th className="px-6 py-4 text-center font-black uppercase">🎯 Selective</th>
                    <th className="px-6 py-4 text-center font-black uppercase">🔧 Skills</th>
                  </tr>
                </thead>
                <tbody>
                  {comparisonData.map((row, index) => (
                    <motion.tr
                      key={index}
                      initial={{ opacity: 0, x: -20 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      viewport={{ once: true }}
                      transition={{ delay: index * 0.1, duration: 0.5 }}
                      className="border-b-4 border-white hover:bg-white hover:text-black transition-colors"
                    >
                      <td className="px-6 py-4 font-black">{row.agent}</td>
                      <td className="px-6 py-4 text-center">
                        {row.basic === true && <Check className="w-6 h-6 mx-auto" strokeWidth={3} />}
                        {row.basic === false && <X className="w-6 h-6 mx-auto" strokeWidth={3} />}
                        {row.basic === 'warning' && <AlertCircle className="w-6 h-6 mx-auto" strokeWidth={3} />}
                      </td>
                      <td className="px-6 py-4 text-center">
                        {row.nested === true && <Check className="w-6 h-6 mx-auto" strokeWidth={3} />}
                        {row.nested === false && <X className="w-6 h-6 mx-auto" strokeWidth={3} />}
                      </td>
                      <td className="px-6 py-4 text-center">
                        {row.selective === true && <Check className="w-6 h-6 mx-auto" strokeWidth={3} />}
                        {row.selective === false && <X className="w-6 h-6 mx-auto" strokeWidth={3} />}
                      </td>
                      <td className="px-6 py-4 text-center">
                        {row.skills === true && <Check className="w-6 h-6 mx-auto" strokeWidth={3} />}
                        {row.skills === false && <X className="w-6 h-6 mx-auto" strokeWidth={3} />}
                        {row.skills === 'warning' && <AlertCircle className="w-6 h-6 mx-auto" strokeWidth={3} />}
                      </td>
                    </motion.tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="px-6 py-6 bg-yellow-400 text-black border-t-4 border-white">
              <p className="text-center font-black uppercase text-lg">
                With Agentfill: Full support across all agents ✓
              </p>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Usage Section */}
      <section className="relative py-24 px-6 border-b-4 border-black">
        <div className="max-w-6xl mx-auto">
          <motion.h2
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="text-[clamp(2.5rem,8vw,5rem)] font-black uppercase leading-none mb-16"
          >
            What You
            <br />
            <span className="bg-black text-white px-4 inline-block -rotate-1">Get</span>
          </motion.h2>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="border-4 border-black p-8 bg-white"
            >
              <h3 className="text-3xl font-black uppercase mb-6">Directory Structure</h3>
              <div className="bg-black text-white p-6 font-mono text-sm border-4 border-black">
                <div className="mb-1">project/</div>
                <div className="mb-1 text-yellow-400">├── AGENTS.md <span className="text-white opacity-60"># Project-wide</span></div>
                <div className="mb-1">└── src/</div>
                <div className="mb-1 ml-4">└── api/</div>
                <div className="text-yellow-400 ml-8">└── AGENTS.md <span className="text-white opacity-60"># API-specific</span></div>
              </div>
              <p className="mt-6 text-lg leading-relaxed">
                When working in <code className="bg-yellow-400 px-2 py-1 font-mono">src/api/</code>, both AGENTS.md files apply - with the API-specific one taking precedence.
              </p>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: 0.2, duration: 0.6 }}
              className="border-4 border-black p-8 bg-white"
            >
              <h3 className="text-3xl font-black uppercase mb-6">Shared Skills</h3>
              <div className="bg-black text-white p-6 font-mono text-sm border-4 border-black">
                <div className="mb-1">.agents/</div>
                <div className="mb-1 ml-4">└── skills/</div>
                <div className="text-yellow-400 mb-1 ml-8">└── my-skill/</div>
                <div className="ml-12">└── SKILL.md</div>
              </div>
              <p className="mt-6 text-lg leading-relaxed">
                Skills are symlinked to each agent's native skills directory, enabling native discovery, hot reloading, and cross-agent compatibility.
              </p>
            </motion.div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="relative py-24 px-6 bg-yellow-400">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="max-w-5xl mx-auto text-center"
        >
          <h2 className="text-[clamp(2.5rem,8vw,6rem)] font-black uppercase leading-none mb-8">
            One Install
            <br />
            To Fill Them All
          </h2>
          <p className="text-2xl font-bold mb-12 max-w-3xl mx-auto">
            Standardize AGENTS.md across Claude Code, Gemini CLI, Cursor, and beyond.
          </p>
          <div className="border-4 border-black p-6 bg-white shadow-[12px_12px_0px_0px_rgba(0,0,0,1)] max-w-4xl mx-auto">
            <div className="flex items-center justify-between gap-4 flex-wrap">
              <code className="text-sm md:text-base font-mono flex-1 text-left break-all">
                {installCommand}
              </code>
              <motion.button
                whileHover={{ scale: 1.05, x: 2, y: 2 }}
                whileTap={{ scale: 0.95 }}
                onClick={copyToClipboard}
                className="flex-shrink-0 bg-black text-white border-4 border-black px-6 py-3 font-black uppercase transition-all flex items-center gap-2 hover:bg-gray-900"
              >
                {copied ? (
                  <>
                    <Check className="w-5 h-5" strokeWidth={3} />
                    <span>Copied!</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-5 h-5" strokeWidth={3} />
                    <span>Copy</span>
                  </>
                )}
              </motion.button>
            </div>
          </div>
        </motion.div>
      </section>

      {/* Footer */}
      <footer className="relative py-12 px-6 border-t-4 border-black bg-white">
        <div className="max-w-7xl mx-auto">
          <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-8">
            <div className="text-left max-w-lg">
              <p className="font-bold mb-2 uppercase">Licensed under:</p>
              <p className="leading-relaxed">
                <a href="https://blueoakcouncil.org/license/1.0.0" className="underline hover:bg-yellow-400 transition-colors">
                  Blue Oak Model License 1.0.0
                </a>
                {' '}or{' '}
                <a href="https://www.apache.org/licenses/LICENSE-2.0" className="underline hover:bg-yellow-400 transition-colors">
                  Apache License 2.0
                </a>
              </p>
            </div>
            <div className="flex flex-wrap gap-6">
              <a
                href="https://github.com/nevir/agentfill"
                className="font-black uppercase border-b-4 border-black hover:bg-yellow-400 transition-colors pb-1"
              >
                GitHub
              </a>
              <a
                href="https://agents.md"
                className="font-black uppercase border-b-4 border-black hover:bg-yellow-400 transition-colors pb-1"
              >
                AGENTS.md
              </a>
              <a
                href="https://agentskills.io"
                className="font-black uppercase border-b-4 border-black hover:bg-yellow-400 transition-colors pb-1"
              >
                Agent Skills
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}