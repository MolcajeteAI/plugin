# Response Templates

Complete template examples for simple and detailed research responses.

## Simple Response Template

### Template Structure

```markdown
# [Concise, Specific Title]

[Direct answer to the question in 1-3 paragraphs. Include code examples inline if applicable.]

[Optional: Additional context or important notes]

## Sources
- [URL 1] - [Brief description]
- [URL 2] - [Brief description]
- [URL 3] - [Brief description]
```

### Complete Example: Git Amend

```markdown
# How to Amend a Git Commit

Use `git commit --amend` to modify the most recent commit. This command opens your editor to change the commit message and includes any currently staged changes in the amended commit.

If you don't want to edit the commit message, use:
```bash
git commit --amend --no-edit
```

**Important:** Only amend commits that haven't been pushed to a shared branch, as amending rewrites commit history.

## Sources
- https://git-scm.com/docs/git-commit - Official git commit documentation
- https://github.com/git-guides/git-commit - GitHub's git commit guide
```

### Complete Example: Claude Code Stop Hook

```markdown
# What is the Stop Hook in Claude Code?

The Stop hook is an event that triggers when the main agent finishes responding naturally (not when interrupted by the user). It fires after task completion, allowing you to run automated actions like playing sounds, logging activity, or triggering follow-up workflows.

Configure it in your `settings.json`:
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "your-command-here"
          }
        ]
      }
    ]
  }
}
```

The Stop hook includes a `stop_hook_active` field in its input to prevent infinite loops when hooks trigger continuation.

## Sources
- https://code.claude.com/docs/en/hooks.md - Hook events reference
- https://code.claude.com/docs/en/hooks-guide.md - Hooks implementation guide
```

### Complete Example: Python List Comprehension

```markdown
# How to Use Python List Comprehensions

List comprehensions provide a concise way to create lists in Python. The basic syntax is:
```python
[expression for item in iterable if condition]
```

Example - create a list of squares for even numbers:
```python
squares = [x**2 for x in range(10) if x % 2 == 0]
# Result: [0, 4, 16, 36, 64]
```

List comprehensions are generally faster and more readable than equivalent for-loops for simple transformations.

## Sources
- https://docs.python.org/3/tutorial/datastructures.html - Python list comprehensions tutorial
- https://peps.python.org/pep-0202/ - List comprehensions PEP
```

## Detailed Response Template

### Template Structure

```markdown
# [Descriptive, Comprehensive Title]

[Executive summary: 2-3 sentences providing high-level overview of the topic and what the reader will learn]

## Overview
[Context and background information. Why is this topic important? What problem does it solve? How does it fit into the broader ecosystem?]

## [Major Topic 1]
[Detailed explanation of the first major aspect. Include examples, code samples, or specific details.]

### [Subtopic 1.1]
[If needed, break down complex topics into subsections]

### [Subtopic 1.2]
[Additional details]

## [Major Topic 2]
[Second major aspect with similar level of detail]

## [Major Topic 3]
[Third major aspect - adjust number of sections based on topic complexity]

## Key Takeaways
- [Most important point to remember]
- [Second critical insight]
- [Third essential concept]
- [Fourth key practice or recommendation]
- [Fifth summary point if applicable]

## Sources
- [URL 1] - [Description of information from this source]
- [URL 2] - [Description]
- [URL 3] - [Description]
- [URL 4] - [Description]
- [URL 5+] - [Description]
```

### Complete Example: Claude Code Hooks

```markdown
# Claude Code Hooks: Complete Guide

Claude Code hooks are event-driven commands that execute automatically when specific events occur during agent execution. They enable workflow automation, custom notifications, and intelligent process control without manual intervention.

## Overview

Hooks provide a powerful extension mechanism for Claude Code, allowing you to respond to nine different event types throughout the agent lifecycle. Each hook can run shell commands, validate operations, or even prevent actions from executing based on custom logic.

Hooks are configured in `settings.json` files at either the global (`~/.claude/settings.json`) or project level (`.claude/settings.json`), with project-level hooks taking precedence.

## Available Hook Events

### PreToolUse
Executes after tool parameters are determined but before the tool runs. Useful for:
- Validating tool parameters
- Blocking dangerous operations
- Logging planned actions
- Enriching context before execution

Example: Block commits containing "TODO" comments
```json
{
  "event": "PreToolUse",
  "matcher": "Bash(git commit*)",
  "command": "grep -r 'TODO' src/ && exit 2 || exit 0"
}
```

### PostToolUse
Runs immediately after a tool completes successfully. Use for:
- Processing tool output
- Triggering follow-up actions
- Logging results
- Validating outcomes

### Stop
Triggers when the main agent finishes responding (excluding user interrupts). Enables:
- Task completion notifications
- Automated workflow continuation
- Quality checks before stopping
- Result summaries

Includes `stop_hook_active` flag to prevent infinite loops.

### Notification
Fires when permission is needed or after 60 seconds of idle time. Perfect for:
- Audio alerts when attention needed
- Desktop notifications
- External system integration
- Activity monitoring

### SubagentStop
Activates when a Task tool (subagent) completes. Useful for:
- Tracking subagent execution
- Performance monitoring
- Completion notifications
- Workflow orchestration

### UserPromptSubmit
Runs when users submit prompts, before processing. Enables:
- Input validation
- Context injection
- Request blocking
- Audit logging

### PreCompact
Executes before context compaction operations. Use for:
- Preserving important context
- Logging pre-compaction state
- Preventing compaction under conditions

### SessionStart
Fires at session initialization or resumption. Good for:
- Environment setup
- Loading project context
- Initialization checks
- Welcome messages

### SessionEnd
Triggers when a session terminates. Useful for:
- Cleanup operations
- Session summaries
- State persistence
- Resource cleanup

## Hook Configuration

### Basic Structure
```json
{
  "hooks": {
    "EventType": [
      {
        "matcher": "pattern",
        "hooks": [
          {
            "type": "command",
            "command": "shell command"
          }
        ]
      }
    ]
  }
}
```

### Matcher Patterns
- `"*"` - Match all events of this type
- `"Bash(git commit*)"` - Match specific tool with pattern
- `"Read(/path/**)"` - Match file paths
- Tool-specific patterns vary by event type

### Exit Codes
- `0` - Success, continue normally
- `1` - Error (shown to user and Claude)
- `2` - Block operation (error shown, operation prevented)

### Environment Variables
- `${CLAUDE_PLUGIN_ROOT}` - Plugin directory path
- Standard shell environment available

## Common Use Cases

### Audio Feedback
```json
{
  "hooks": {
    "Stop": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "afplay /System/Library/Sounds/Hero.aiff"
      }]
    }]
  }
}
```

### Pre-commit Validation
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash(git commit*)",
      "hooks": [{
        "type": "command",
        "command": "./scripts/pre-commit-check.sh"
      }]
    }]
  }
}
```

### Protected Files
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Write(.env*)",
      "hooks": [{
        "type": "command",
        "command": "echo 'Cannot modify .env files' && exit 2"
      }]
    }]
  }
}
```

## Best Practices

### Performance
- Keep hooks fast (< 100ms ideal)
- Run expensive operations asynchronously
- Use background processes for notifications

### Reliability
- Check exit codes properly
- Handle errors gracefully
- Test hooks thoroughly
- Provide clear error messages

### Security
- Validate all inputs in hooks
- Don't expose sensitive data in errors
- Use absolute paths for scripts
- Limit hook permissions appropriately

### Maintainability
- Document hook purposes
- Keep hook scripts in version control
- Use descriptive command names
- Organize hooks by purpose

## Key Takeaways
- Hooks enable event-driven automation without manual intervention
- Nine event types cover the complete agent lifecycle
- Exit code 2 blocks operations, 0 continues, 1 shows errors
- Project-level hooks override global hooks
- Use `stop_hook_active` flag to prevent infinite continuation loops

## Sources
- https://code.claude.com/docs/en/hooks.md - Complete hooks reference
- https://code.claude.com/docs/en/hooks-guide.md - Hooks implementation guide
- https://code.claude.com/docs/en/claude_code_docs_map.md - Documentation overview
```

### Complete Example: React Hooks Overview

```markdown
# React Hooks: Comprehensive Guide

React Hooks are functions that let you use state and other React features in function components. Introduced in React 16.8, hooks enable component logic reuse without changing component hierarchy or using class components.

## Overview

Before hooks, React developers had to use class components to access features like state and lifecycle methods. Hooks solve several problems: wrapper hell from higher-order components, confusing lifecycle methods, and the difficulty of reusing stateful logic between components.

Hooks follow two rules: only call hooks at the top level (not in loops or conditions), and only call hooks from React functions (not regular JavaScript functions).

## Built-in Hooks

### useState
Manages local component state. Returns a state value and a setter function.

```jsx
const [count, setCount] = useState(0);

// Update state
setCount(count + 1);

// Or use function form for updates based on previous state
setCount(prevCount => prevCount + 1);
```

### useEffect
Performs side effects in function components. Replaces lifecycle methods like componentDidMount, componentDidUpdate, and componentWillUnmount.

```jsx
useEffect(() => {
  // Effect runs after render
  document.title = `Count: ${count}`;

  // Optional cleanup function
  return () => {
    // Cleanup runs before next effect and on unmount
  };
}, [count]); // Dependencies array - effect runs when count changes
```

### useContext
Accesses React Context without nesting consumers.

```jsx
const theme = useContext(ThemeContext);
```

### useReducer
Alternative to useState for complex state logic. Similar to Redux reducers.

```jsx
const [state, dispatch] = useReducer(reducer, initialState);
```

### useCallback
Memoizes callback functions to prevent unnecessary re-renders.

```jsx
const memoizedCallback = useCallback(
  () => {
    doSomething(a, b);
  },
  [a, b] // Recreate only when dependencies change
);
```

### useMemo
Memoizes expensive computations.

```jsx
const memoizedValue = useMemo(() => computeExpensiveValue(a, b), [a, b]);
```

### useRef
Creates a mutable reference that persists across renders.

```jsx
const inputRef = useRef(null);

// Access DOM element
inputRef.current.focus();
```

## Custom Hooks

Create reusable logic by extracting hooks into custom functions. Custom hooks must start with "use" and can call other hooks.

```jsx
function useWindowWidth() {
  const [width, setWidth] = useState(window.innerWidth);

  useEffect(() => {
    const handleResize = () => setWidth(window.innerWidth);
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return width;
}

// Usage
const width = useWindowWidth();
```

## Common Patterns

### Data Fetching
```jsx
function useDataFetch(url) {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(url)
      .then(res => res.json())
      .then(data => {
        setData(data);
        setLoading(false);
      });
  }, [url]);

  return { data, loading };
}
```

### Form Handling
```jsx
function useFormInput(initialValue) {
  const [value, setValue] = useState(initialValue);

  const handleChange = (e) => setValue(e.target.value);

  return {
    value,
    onChange: handleChange
  };
}
```

## Best Practices

### Dependencies
Always include all values from component scope that change over time in dependency arrays. Use ESLint plugin `eslint-plugin-react-hooks` to catch mistakes.

### Effect Cleanup
Return cleanup functions from effects to prevent memory leaks:
```jsx
useEffect(() => {
  const subscription = subscribe();
  return () => subscription.unsubscribe();
}, []);
```

### Avoid Infinite Loops
Be careful with dependency arrays. Missing dependencies or incorrect arrays can cause infinite renders.

### State Updates
Use functional updates when new state depends on previous state:
```jsx
setCount(c => c + 1); // Correct
setCount(count + 1); // May be stale in async contexts
```

## Key Takeaways
- Hooks enable state and lifecycle features in function components
- useState and useEffect are the most commonly used hooks
- Custom hooks enable logic reuse without component hierarchy changes
- Always follow the Rules of Hooks (top-level calls, React functions only)
- Use dependency arrays correctly to avoid bugs and performance issues

## Sources
- https://react.dev/reference/react - Official React Hooks reference
- https://react.dev/learn/hooks - React Hooks tutorial
- https://github.com/facebook/react/blob/main/packages/react/src/ReactHooks.js - Hooks implementation
- https://react.dev/learn/reusing-logic-with-custom-hooks - Custom Hooks guide
- https://www.npmjs.com/package/eslint-plugin-react-hooks - ESLint plugin for Hooks rules
```

## Template Selection Guide

| Query Type | Template | Indicators |
|------------|----------|------------|
| Specific how-to | Simple | "How do I...", single task, quick answer |
| Definition | Simple | "What is...", single concept |
| Command reference | Simple | Syntax lookup, parameter info |
| Quick example | Simple | "Show me how to..." |
| Comprehensive overview | Detailed | "Research all...", "Give me an intro" |
| Multiple concepts | Detailed | Several related topics |
| Comparison | Detailed | "Compare X and Y" |
| Best practices guide | Detailed | "Best practices for..." |

## Tone and Style

### Simple Responses
- Direct and practical
- Get to the answer quickly
- Code-heavy when applicable
- Minimal background information

### Detailed Responses
- Educational and comprehensive
- Provide context and rationale
- Multiple examples
- Organized into logical sections
- Balance depth with readability
