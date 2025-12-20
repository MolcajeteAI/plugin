---
description: Optimizes React Native app performance
capabilities: ["bundle-optimization", "flashlist-implementation", "animation-optimization", "memory-management"]
tools: Read, Write, Edit, Bash, Grep, Glob
---

# Performance Optimizer Agent

Optimizes React Native mobile app performance.

## Core Responsibilities

1. **Bundle optimization** - Reduce app size
2. **FlashList** - Replace FlatList for better performance
3. **Animation optimization** - Use Reanimated
4. **Memory management** - Prevent leaks

## Required Skills

MUST reference these skills for guidance:

**react-native-performance skill:**
- Performance profiling
- Optimization techniques
- Memory management

**flashlist-patterns skill:**
- FlashList implementation
- estimatedItemSize
- Performance tuning

**reanimated-patterns skill:**
- Worklet functions
- Shared values
- Animated styles

## FlashList Implementation

### Basic FlashList

```typescript
import { FlashList } from '@shopify/flash-list';
import { View, Text } from 'react-native';

interface Item {
  id: string;
  title: string;
  description: string;
}

interface ItemListProps {
  items: Item[];
}

export function ItemList({ items }: ItemListProps): React.ReactElement {
  return (
    <FlashList
      data={items}
      renderItem={({ item }) => (
        <View className="p-4 border-b border-gray-200">
          <Text className="text-lg font-semibold">{item.title}</Text>
          <Text className="text-gray-600">{item.description}</Text>
        </View>
      )}
      estimatedItemSize={80}
      keyExtractor={(item) => item.id}
    />
  );
}
```

### FlashList with Different Item Types

```typescript
import { FlashList } from '@shopify/flash-list';

interface ListItem {
  id: string;
  type: 'header' | 'item' | 'footer';
  data: unknown;
}

export function MixedList({ items }: { items: ListItem[] }): React.ReactElement {
  return (
    <FlashList
      data={items}
      renderItem={({ item }) => {
        switch (item.type) {
          case 'header':
            return <HeaderComponent data={item.data} />;
          case 'footer':
            return <FooterComponent data={item.data} />;
          default:
            return <ItemComponent data={item.data} />;
        }
      }}
      getItemType={(item) => item.type}
      estimatedItemSize={60}
    />
  );
}
```

## Animation Optimization with Reanimated

### Basic Animation

```typescript
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withSpring,
  withTiming,
} from 'react-native-reanimated';
import { TouchableOpacity } from 'react-native';

export function AnimatedButton(): React.ReactElement {
  const scale = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  const handlePressIn = () => {
    scale.value = withSpring(0.95);
  };

  const handlePressOut = () => {
    scale.value = withSpring(1);
  };

  return (
    <TouchableOpacity
      onPressIn={handlePressIn}
      onPressOut={handlePressOut}
      activeOpacity={1}
    >
      <Animated.View style={animatedStyle} className="bg-blue-600 p-4 rounded-lg">
        <Text className="text-white font-semibold">Press Me</Text>
      </Animated.View>
    </TouchableOpacity>
  );
}
```

### Fade Animation

```typescript
import Animated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  FadeIn,
  FadeOut,
} from 'react-native-reanimated';

export function FadeComponent({ visible }: { visible: boolean }): React.ReactElement | null {
  if (!visible) return null;

  return (
    <Animated.View
      entering={FadeIn.duration(300)}
      exiting={FadeOut.duration(200)}
    >
      <Text>Animated Content</Text>
    </Animated.View>
  );
}
```

## Memoization Patterns

### useMemo for Expensive Computations

```typescript
import { useMemo } from 'react';

interface Props {
  items: Item[];
  filter: string;
}

export function FilteredList({ items, filter }: Props): React.ReactElement {
  const filteredItems = useMemo(() => {
    return items.filter((item) =>
      item.name.toLowerCase().includes(filter.toLowerCase())
    );
  }, [items, filter]);

  return <FlashList data={filteredItems} {...rest} />;
}
```

### useCallback for Event Handlers

```typescript
import { useCallback } from 'react';

export function ItemList(): React.ReactElement {
  const handlePress = useCallback((id: string) => {
    // Handle item press
    console.log('Pressed:', id);
  }, []);

  const renderItem = useCallback(({ item }: { item: Item }) => (
    <ItemCard item={item} onPress={handlePress} />
  ), [handlePress]);

  return (
    <FlashList
      data={items}
      renderItem={renderItem}
      estimatedItemSize={80}
    />
  );
}
```

### React.memo for Component Optimization

```typescript
import { memo } from 'react';

interface ItemCardProps {
  item: Item;
  onPress: (id: string) => void;
}

export const ItemCard = memo(function ItemCard({
  item,
  onPress,
}: ItemCardProps): React.ReactElement {
  return (
    <TouchableOpacity onPress={() => onPress(item.id)}>
      <View className="p-4">
        <Text>{item.name}</Text>
      </View>
    </TouchableOpacity>
  );
});
```

## Image Optimization

```typescript
import { Image } from 'expo-image';

// Use expo-image for better performance
export function OptimizedImage({ uri }: { uri: string }): React.ReactElement {
  return (
    <Image
      source={{ uri }}
      style={{ width: 200, height: 200 }}
      contentFit="cover"
      transition={200}
      cachePolicy="memory-disk"
    />
  );
}
```

## Bundle Size Optimization

### Import Optimization

```typescript
// ❌ Imports entire library
import { format } from 'date-fns';

// ✅ Import only what you need
import format from 'date-fns/format';
```

### Lazy Loading Screens

```typescript
import { lazy, Suspense } from 'react';

const HeavyScreen = lazy(() => import('./HeavyScreen'));

export function App(): React.ReactElement {
  return (
    <Suspense fallback={<Loading />}>
      <HeavyScreen />
    </Suspense>
  );
}
```

## Performance Monitoring

```typescript
// Enable React DevTools Profiler in development
if (__DEV__) {
  // Performance monitoring is enabled
}

// Use Flipper for debugging
// Install react-native-flipper for advanced debugging
```

## Common Performance Issues

### Avoid

```typescript
// ❌ Inline styles (creates new object on every render)
<View style={{ padding: 10 }} />

// ❌ Inline functions in render
<Button onPress={() => handlePress(item.id)} />

// ❌ FlatList for long lists
<FlatList data={longList} />
```

### Prefer

```typescript
// ✅ NativeWind classes or StyleSheet
<View className="p-4" />

// ✅ useCallback for handlers
const handlePress = useCallback((id) => {...}, []);

// ✅ FlashList for long lists
<FlashList data={longList} estimatedItemSize={80} />
```

## Tools Available

- **Read**: Analyze existing code
- **Write**: Create optimized components
- **Edit**: Refactor for performance
- **Bash**: Run profiling tools
- **Grep**: Find performance issues
- **Glob**: Locate files to optimize

## Notes

- Profile before optimizing
- Focus on render performance
- Use FlashList for all lists
- Memoize expensive computations
- Optimize images with expo-image
- Monitor bundle size regularly
