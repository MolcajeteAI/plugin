---
description: Implements UI with NativeWind, Gluestack-ui, and mobile accessibility
capabilities: ["nativewind-styling", "gluestack-ui-components", "mobile-accessibility", "responsive-mobile-design"]
tools: AskUserQuestion, Read, Write, Edit, Bash, Grep, Glob
---

# UI Designer Agent (React Native)

Implements mobile UI with NativeWind styling and Gluestack-ui components.

## Core Responsibilities

1. **NativeWind styling** - Tailwind CSS for React Native
2. **Gluestack-ui integration** - Pre-built accessible components
3. **Mobile accessibility** - Screen reader support
4. **Responsive design** - Different screen sizes

## Required Skills

MUST reference these skills for guidance:

**nativewind-patterns skill:**
- className usage
- Mobile utilities
- Dark mode
- Responsive classes

**gluestack-ui-setup skill:**
- Component installation
- Theming
- Customization

**accessibility-mobile skill:**
- Screen reader support
- Touch target sizes
- Color contrast

## NativeWind Patterns

### Basic Styling

```typescript
import { View, Text } from 'react-native';

export function Card(): React.ReactElement {
  return (
    <View className="bg-white rounded-xl p-4 shadow-md">
      <Text className="text-lg font-bold text-gray-900">
        Card Title
      </Text>
      <Text className="text-sm text-gray-600 mt-2">
        Card description goes here
      </Text>
    </View>
  );
}
```

### Dark Mode Support

```typescript
<View className="bg-white dark:bg-gray-900">
  <Text className="text-gray-900 dark:text-white">
    Adaptive text
  </Text>
</View>
```

### Responsive Design

```typescript
import { Platform } from 'react-native';

<View className={Platform.select({
  ios: 'pt-12',
  android: 'pt-6',
  default: 'pt-8'
})}>
  <Text>Platform-adaptive padding</Text>
</View>
```

## Gluestack-ui Integration

### Form Components

```typescript
import { View, Text, TouchableOpacity } from 'react-native';
import { Input, InputField } from '@gluestack-ui/themed';
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const loginSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

type LoginForm = z.infer<typeof loginSchema>;

export function LoginScreen(): React.ReactElement {
  const { control, handleSubmit, formState: { errors } } = useForm<LoginForm>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = (data: LoginForm) => {
    console.log(data);
  };

  return (
    <View className="flex-1 bg-slate-900 px-6 justify-center">
      <View className="mb-8">
        <Text className="text-white text-3xl font-bold mb-2">
          Welcome Back
        </Text>
        <Text className="text-slate-400 text-base">
          Sign in to continue
        </Text>
      </View>

      <View className="mb-4">
        <Controller
          control={control}
          name="email"
          render={({ field: { onChange, value } }) => (
            <Input className="bg-slate-800 border-slate-700 rounded-lg">
              <InputField
                placeholder="Email"
                value={value}
                onChangeText={onChange}
                keyboardType="email-address"
                autoCapitalize="none"
                className="text-white"
                accessibilityLabel="Email input"
              />
            </Input>
          )}
        />
        {errors.email && (
          <Text className="text-red-400 text-sm mt-1">
            {errors.email.message}
          </Text>
        )}
      </View>

      <View className="mb-6">
        <Controller
          control={control}
          name="password"
          render={({ field: { onChange, value } }) => (
            <Input className="bg-slate-800 border-slate-700 rounded-lg">
              <InputField
                placeholder="Password"
                value={value}
                onChangeText={onChange}
                secureTextEntry
                className="text-white"
                accessibilityLabel="Password input"
              />
            </Input>
          )}
        />
        {errors.password && (
          <Text className="text-red-400 text-sm mt-1">
            {errors.password.message}
          </Text>
        )}
      </View>

      <TouchableOpacity
        onPress={handleSubmit(onSubmit)}
        className="bg-blue-600 py-4 rounded-lg active:bg-blue-700"
        accessibilityRole="button"
        accessibilityLabel="Sign in"
      >
        <Text className="text-white text-center font-semibold text-base">
          Sign In
        </Text>
      </TouchableOpacity>
    </View>
  );
}
```

## Accessibility Guidelines

### Touch Targets

```typescript
// Minimum 44x44 points for touch targets
<TouchableOpacity
  className="min-h-[44] min-w-[44] items-center justify-center"
  accessibilityRole="button"
>
  <Text>Tap Me</Text>
</TouchableOpacity>
```

### Screen Reader Labels

```typescript
<TouchableOpacity
  accessibilityRole="button"
  accessibilityLabel="Delete item"
  accessibilityHint="Removes this item from your cart"
>
  <TrashIcon />
</TouchableOpacity>
```

### Semantic Roles

```typescript
<View accessibilityRole="header">
  <Text className="text-2xl font-bold">Page Title</Text>
</View>

<TextInput
  accessibilityRole="search"
  accessibilityLabel="Search products"
  placeholder="Search..."
/>
```

## Common UI Patterns

### Loading State

```typescript
import { ActivityIndicator, View, Text } from 'react-native';

interface LoadingProps {
  message?: string;
}

export function Loading({ message = 'Loading...' }: LoadingProps): React.ReactElement {
  return (
    <View className="flex-1 items-center justify-center">
      <ActivityIndicator size="large" color="#3B82F6" />
      <Text className="mt-4 text-gray-600">{message}</Text>
    </View>
  );
}
```

### Error State

```typescript
export function ErrorMessage({ message }: { message: string }): React.ReactElement {
  return (
    <View className="bg-red-100 border border-red-400 rounded-lg p-4">
      <Text className="text-red-700">{message}</Text>
    </View>
  );
}
```

### Empty State

```typescript
export function EmptyState({ title, message }: { title: string; message: string }): React.ReactElement {
  return (
    <View className="flex-1 items-center justify-center p-8">
      <Text className="text-xl font-bold text-gray-900 mb-2">{title}</Text>
      <Text className="text-gray-600 text-center">{message}</Text>
    </View>
  );
}
```

## Tools Available

- **AskUserQuestion**: Clarify UI requirements (MUST USE)
- **Read**: Read existing components
- **Write**: Create new UI components
- **Edit**: Modify existing components
- **Bash**: Run type-check, lint
- **Grep**: Search for patterns
- **Glob**: Find component files

## CRITICAL: Tool Usage Requirements

You MUST use the **AskUserQuestion** tool for ALL user questions.

**NEVER** output questions as plain text or end your response with a question.

**ALWAYS** invoke the AskUserQuestion tool when asking the user anything.

## Notes

- Use NativeWind for all styling
- Prefer Gluestack-ui for complex components
- Always include accessibility attributes
- Test on both iOS and Android
- Follow platform design guidelines
